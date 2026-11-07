import Foundation

/// Watches one directory with a kqueue vnode source. Callbacks are delivered on the main queue.
/// `onChange` fires (debounced) when entries are added, removed or renamed inside the folder.
/// `onFolderGone` fires when the folder itself is deleted, renamed or its volume unmounts.
public final class FolderMonitor {
    private let monitoredURL: URL
    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "com.desktopduzen.foldermonitor", qos: .utility)
    private var debounceTimer: DispatchSourceTimer?

    public var debounce: DispatchTimeInterval = .milliseconds(200)
    public var onChange: (() -> Void)?
    public var onFolderGone: (() -> Void)?

    public init(url: URL) {
        self.monitoredURL = url
    }

    public var isRunning: Bool { source != nil }

    @discardableResult
    public func start() -> Bool {
        stop()
        let fd = open(monitoredURL.path, O_EVTONLY)
        guard fd >= 0 else { return false }
        fileDescriptor = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .attrib, .link, .rename, .delete, .revoke],
            queue: queue
        )
        src.setEventHandler { [weak self, weak src] in
            guard let self = self, let src = src else { return }
            let flags = src.data
            if flags.contains(.delete) || flags.contains(.rename) || flags.contains(.revoke) {
                DispatchQueue.main.async { self.onFolderGone?() }
            }
            self.scheduleDebouncedChange()
        }
        // The cancel handler owns the descriptor, so it is closed exactly once.
        src.setCancelHandler {
            close(fd)
        }
        source = src
        src.resume()
        return true
    }

    public func stop() {
        // The timer is only touched on `queue`, which removes the data race with the event handler.
        queue.sync {
            debounceTimer?.cancel()
            debounceTimer = nil
        }
        if let src = source {
            src.cancel()
            source = nil
        }
        fileDescriptor = -1
    }

    private func scheduleDebouncedChange() {
        debounceTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + debounce)
        timer.setEventHandler { [weak self] in
            DispatchQueue.main.async { self?.onChange?() }
        }
        debounceTimer = timer
        timer.resume()
    }

    deinit {
        stop()
    }
}
