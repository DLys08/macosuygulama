import Foundation

public class AutoSortService {
    public static let shared = AutoSortService()
    
    private var desktopMonitor: FolderMonitor?
    private let fileManager = FileManager.default
    
    public init() {}
    
    public func startMonitoring(rules: [AutoSortRule], zones: [ZoneModel], isPro: Bool) {
        stopMonitoring()
        guard isPro else { return }
        
        let desktop = FileManagerService.shared.desktopURL
        desktopMonitor = FolderMonitor(url: desktop)
        desktopMonitor?.onChange = { [weak self] in
            self?.runAutoSort(rules: rules, zones: zones, isPro: isPro)
        }
        desktopMonitor?.start()
    }
    
    public func stopMonitoring() {
        desktopMonitor?.stop()
        desktopMonitor = nil
    }
    
    @discardableResult
    public func runAutoSort(rules: [AutoSortRule], zones: [ZoneModel], isPro: Bool) -> Int {
        guard isPro else { return 0 }
        
        let desktop = FileManagerService.shared.desktopURL
        guard let items = try? fileManager.contentsOfDirectory(at: desktop, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        
        var movedCount = 0
        
        for item in items {
            // Do not sort the Zones folder or folders themselves
            if item.lastPathComponent == "Zones" { continue }
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir { continue }
            
            let ext = item.pathExtension.lowercased()
            guard !ext.isEmpty else { continue }
            
            // Find first matching rule
            for rule in rules where rule.isEnabled {
                if rule.extensions.map({ $0.lowercased() }).contains(ext) {
                    // Match found! Find target zone
                    if let targetZone = zones.first(where: {
                        if let id = rule.targetZoneID { return $0.id == id }
                        return $0.title.localizedCaseInsensitiveCompare(rule.targetZoneTitle) == .orderedSame
                    }), targetZone.type != .app {
                        let targetFolder = URL(fileURLWithPath: targetZone.resolvedFolderPath)
                        if FileManagerService.shared.moveFile(from: item, toDirectory: targetFolder) != nil {
                            movedCount += 1
                            break
                        }
                    }
                }
            }
        }
        
        return movedCount
    }
}
