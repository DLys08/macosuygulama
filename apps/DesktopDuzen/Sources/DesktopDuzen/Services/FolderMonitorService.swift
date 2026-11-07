import Foundation

public final class FolderMonitor {
    private let monitoredURL: URL
    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "com.desktopduzen.foldermonitor", qos: .utility)
    private var debounceTimer: DispatchSourceTimer?
    
    public var onChange: (() -> Void)?
    
    public init(url: URL) {
        self.monitoredURL = url
    }
    
    public func start() {
        stop()
        
        fileDescriptor = open(monitoredURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            return
        }
        
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .attrib, .link, .rename, .delete],
            queue: queue
        )
        
        src.setEventHandler { [weak self] in
            self?.scheduleDebouncedChange()
        }
        
        src.setCancelHandler { [weak self] in
            guard let self = self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }
        
        self.source = src
        src.resume()
    }
    
    public func stop() {
        debounceTimer?.cancel()
        debounceTimer = nil
        
        if let src = source {
            src.cancel()
            source = nil
        } else if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }
    
    private func scheduleDebouncedChange() {
        debounceTimer?.cancel()
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + .milliseconds(150))
        timer.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.onChange?()
            }
        }
        debounceTimer = timer
        timer.resume()
    }
    
    deinit {
        stop()
    }
}
