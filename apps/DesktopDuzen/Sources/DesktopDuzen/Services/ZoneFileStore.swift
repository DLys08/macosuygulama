import Foundation
import Combine

/// Live, observable listing of one zone's folder. Owned by the zone's window controller, so it
/// survives SwiftUI view rebuilds. Reacts to adds, deletes, renames and moves done in Finder,
/// and to the folder itself disappearing (deleted, renamed, external drive ejected).
public final class ZoneFileStore: ObservableObject {
    @Published public private(set) var files: [FileItem] = []
    @Published public private(set) var folderMissing: Bool = false
    @Published public private(set) var lastError: String?

    private let fileService: FileManagerService
    private var monitor: FolderMonitor?
    private var watchedPath: String = ""
    private var manualOrder: [String] = []
    private var recheckTimer: Timer?
    private let listQueue = DispatchQueue(label: "com.desktopduzen.zonelisting", qos: .userInitiated)
    private var generation = 0

    public init(fileService: FileManagerService = .shared) {
        self.fileService = fileService
    }

    /// Point the store at a folder. Calling it again with the same path is cheap.
    public func watch(path: String, manualOrder: [String]) {
        self.manualOrder = manualOrder
        guard path != watchedPath || monitor == nil else { return }
        watchedPath = path
        restartMonitor()
        reload()
    }

    public func updateManualOrder(_ order: [String]) {
        guard order != manualOrder else { return }
        manualOrder = order
        reload()
    }

    public func stop() {
        monitor?.stop()
        monitor = nil
        recheckTimer?.invalidate()
        recheckTimer = nil
        watchedPath = ""
    }

    private func restartMonitor() {
        monitor?.stop()
        monitor = nil
        recheckTimer?.invalidate()
        recheckTimer = nil
        guard !watchedPath.isEmpty else { return }

        let m = FolderMonitor(url: URL(fileURLWithPath: watchedPath, isDirectory: true))
        m.onChange = { [weak self] in self?.reload() }
        m.onFolderGone = { [weak self] in
            // The descriptor now points at a dead or moved node; re-resolve by path.
            self?.restartMonitor()
            self?.reload()
        }
        if m.start() {
            monitor = m
        } else {
            // Folder unavailable (missing, permission, unmounted). Poll cheaply until it returns.
            recheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.fileService.folderExists(self.watchedPath) {
                    self.restartMonitor()
                    self.reload()
                }
            }
            recheckTimer?.tolerance = 1.0
        }
    }

    public func reload() {
        let path = watchedPath
        let order = manualOrder
        generation += 1
        let token = generation
        guard !path.isEmpty else {
            files = []
            folderMissing = false
            return
        }
        listQueue.async { [weak self] in
            guard let self = self else { return }
            let exists = self.fileService.folderExists(path)
            let listing = exists ? self.fileService.contentsOfFolder(path: path, manualOrder: order) : []
            DispatchQueue.main.async {
                guard token == self.generation else { return } // A newer reload superseded this one.
                if self.folderMissing != !exists { self.folderMissing = !exists }
                if self.files != listing { self.files = listing }
            }
        }
    }

    public func reportError(_ message: String?) {
        lastError = message
    }

    deinit {
        monitor?.stop()
        recheckTimer?.invalidate()
    }
}
