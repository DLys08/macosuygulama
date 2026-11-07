import Foundation
import SwiftUI
import AppKit
import Combine

public class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var zones: [ZoneModel] = []
    @Published public var stickers: [DesktopSticker] = []
    @Published public var widgets: [DesktopWidget] = []
    @Published public var autoSortRules: [AutoSortRule] = []
    @Published public var settings: AppSettings = AppSettings()
    @Published public var license: LicenseStatus = LicenseStatus()
    
    @Published public var selectedZoneID: UUID?
    @Published public var isAlignmentModeActive: Bool = false
    @Published public var isGlobalSearchPresented: Bool = false
    @Published public var isPaywallPresented: Bool = false
    @Published public var isSettingsPresented: Bool = false
    @Published public var isOnboardingPresented: Bool = false
    @Published public var areAllZonesHidden: Bool = false
    
    private let appSupportURL: URL
    private let stateFileURL: URL
    private var cancellables = Set<AnyCancellable>()
    
    public init(customStorageURL: URL? = nil) {
        if let custom = customStorageURL {
            self.appSupportURL = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.appSupportURL = appSupport.appendingPathComponent("DesktopDuzen", isDirectory: true)
        }
        self.stateFileURL = appSupportURL.appendingPathComponent("state.json")
        
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        
        loadState()
        
        // Setup observers for auto-saving
        $zones.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)
        
        $stickers.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)
            
        $widgets.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)
            
        $settings.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)
            
        $license.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)
            
        $autoSortRules.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)
    }
    
    // MARK: - Pro Entitlements
    
    public var isPro: Bool {
        license.isPro || license.isMockProActive
    }
    
    public func canAddZone() -> Bool {
        if isPro { return true }
        return zones.count < 3
    }
    
    public func canUseTabs() -> Bool {
        return isPro
    }
    
    public func canAutoExpand() -> Bool {
        return isPro
    }
    
    public func canPinOnTop() -> Bool {
        return isPro
    }
    
    public func canUseTheme(_ theme: ZoneTheme) -> Bool {
        if !theme.isPro { return true }
        return isPro
    }
    
    // MARK: - Zone Management
    
    public func createDefaultFileZone(title: String = "Work Files") -> ZoneModel {
        let folder = FileManagerService.shared.createFolderForFileZone(title: title)
        let count = zones.count
        let screen = NSScreen.screens.first?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        
        let width: CGFloat = 340
        let height: CGFloat = 260
        let x = screen.minX + 60 + CGFloat(count % 3) * (width + 24)
        let y = screen.maxY - height - 60 - CGFloat((count / 3) * 300)
        
        let newZone = ZoneModel(
            type: .file,
            title: title,
            frame: CGRect(x: x, y: y, width: width, height: height),
            backingFolderPath: folder.path,
            themeID: "glass_blur"
        )
        zones.append(newZone)
        return newZone
    }
    
    public func createFolderZone(title: String, folderURL: URL) -> ZoneModel {
        let bookmark = FileManagerService.shared.createSecurityBookmark(for: folderURL)
        let count = zones.count
        let screen = NSScreen.screens.first?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        
        let width: CGFloat = 340
        let height: CGFloat = 260
        let x = screen.minX + 60 + CGFloat(count % 3) * (width + 24)
        let y = screen.maxY - height - 60 - CGFloat((count / 3) * 300)
        
        let newZone = ZoneModel(
            type: .folder,
            title: title,
            frame: CGRect(x: x, y: y, width: width, height: height),
            backingFolderPath: folderURL.path,
            securityBookmarkData: bookmark,
            themeID: "slate_titanium"
        )
        zones.append(newZone)
        return newZone
    }
    
    public func createAppZone(title: String = "Favorite Apps", initialApps: [AppItem] = []) -> ZoneModel {
        let count = zones.count
        let screen = NSScreen.screens.first?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        
        let width: CGFloat = 340
        let height: CGFloat = 220
        let x = screen.minX + 60 + CGFloat(count % 3) * (width + 24)
        let y = screen.maxY - height - 60 - CGFloat((count / 3) * 260)
        
        var apps = initialApps
        if apps.isEmpty {
            // Suggest default common apps if present
            let candidatePaths = [
                "/System/Applications/Finder.app",
                "/System/Applications/Mail.app",
                "/Applications/Safari.app",
                "/System/Applications/Utilities/Terminal.app"
            ]
            for path in candidatePaths {
                if let item = FileManagerService.shared.resolveAppInfo(at: path) {
                    apps.append(item)
                }
            }
        }
        
        let newZone = ZoneModel(
            type: .app,
            title: title,
            frame: CGRect(x: x, y: y, width: width, height: height),
            apps: apps,
            themeID: "dark_frost"
        )
        zones.append(newZone)
        return newZone
    }
    
    public func updateZone(_ zone: ZoneModel) {
        if let idx = zones.firstIndex(where: { $0.id == zone.id }) {
            zones[idx] = zone
        }
    }
    
    public func deleteZone(id: UUID, action: ZoneDeleteAction) {
        guard let zone = zones.first(where: { $0.id == id }) else { return }
        if zone.type == .file {
            FileManagerService.shared.deleteZone(folderPath: zone.backingFolderPath, action: action)
        }
        zones.removeAll(where: { $0.id == id })
    }
    
    public func renameZone(id: UUID, newTitle: String) {
        guard let idx = zones.firstIndex(where: { $0.id == id }) else { return }
        var zone = zones[idx]
        zone.title = newTitle
        if zone.type == .file {
            if let newPath = FileManagerService.shared.renameZoneFolder(oldPath: zone.backingFolderPath, newTitle: newTitle) {
                zone.backingFolderPath = newPath
            }
        }
        zones[idx] = zone
    }
    
    // MARK: - Auto-Align
    
    public func autoAlignAllZones() {
        guard let screen = NSScreen.screens.first?.visibleFrame ?? NSScreen.main?.visibleFrame else { return }
        let marginX: CGFloat = 60
        let marginY: CGFloat = 60
        let spacing: CGFloat = 20
        
        var currentX = screen.minX + marginX
        var currentY = screen.maxY - marginY
        var maxHeightInRow: CGFloat = 0
        
        for i in 0..<zones.count {
            let z = zones[i]
            let w = z.frame.width
            let h = z.isCollapsed ? z.collapsedHeight : z.expandedHeight
            
            if currentX + w > screen.maxX - marginX && currentX > screen.minX + marginX {
                currentX = screen.minX + marginX
                currentY -= (maxHeightInRow + spacing)
                maxHeightInRow = 0
            }
            
            zones[i].frame = CGRect(x: currentX, y: currentY - h, width: w, height: h)
            currentX += (w + spacing)
            maxHeightInRow = max(maxHeightInRow, h)
        }
    }
    
    // MARK: - Persistence & Serialization
    
    private struct PersistedState: Codable {
        var zones: [ZoneModel]
        var stickers: [DesktopSticker]
        var widgets: [DesktopWidget]
        var autoSortRules: [AutoSortRule]
        var settings: AppSettings
        var license: LicenseStatus
    }
    
    public func saveState() {
        let state = PersistedState(
            zones: zones,
            stickers: stickers,
            widgets: widgets,
            autoSortRules: autoSortRules,
            settings: settings,
            license: license
        )
        
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: stateFileURL, options: .atomic)
        } catch {
            print("Failed to save DesktopDuzen state: \(error)")
        }
    }
    
    public func loadState() {
        guard FileManager.default.fileExists(atPath: stateFileURL.path),
              let data = try? Data(contentsOf: stateFileURL),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data) else {
            // First time setup - populate starter zones
            populateStarterData()
            return
        }
        
        self.zones = state.zones
        self.stickers = state.stickers
        self.widgets = state.widgets
        self.autoSortRules = state.autoSortRules.isEmpty ? AutoSortRule.defaultRules : state.autoSortRules
        self.settings = state.settings
        self.license = state.license
    }
    
    public func populateStarterData() {
        self.zones = []
        let primaryScreen = NSScreen.screens.first ?? NSScreen.main
        let screen = primaryScreen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        
        let width: CGFloat = 340
        let height: CGFloat = 260
        let topY = screen.maxY - height - 40
        
        let zone1Folder = FileManagerService.shared.createFolderForFileZone(title: "Active Projects")
        let zone1 = ZoneModel(
            type: .file,
            title: "Active Projects",
            frame: CGRect(x: screen.minX + 60, y: topY, width: width, height: height),
            backingFolderPath: zone1Folder.path,
            themeID: "glass_blur"
        )
        self.zones.append(zone1)
        
        let zone2Folder = FileManagerService.shared.createFolderForFileZone(title: "Downloads & Media")
        let zone2 = ZoneModel(
            type: .file,
            title: "Downloads & Media",
            frame: CGRect(x: screen.minX + 60 + width + 24, y: topY, width: width, height: height),
            backingFolderPath: zone2Folder.path,
            themeID: "glass_blur"
        )
        self.zones.append(zone2)
        
        var apps: [AppItem] = []
        for path in ["/System/Applications/Finder.app", "/System/Applications/Mail.app", "/Applications/Safari.app", "/System/Applications/Utilities/Terminal.app"] {
            if let item = FileManagerService.shared.resolveAppInfo(at: path) {
                apps.append(item)
            }
        }
        let zone3 = ZoneModel(
            type: .app,
            title: "Quick Launcher",
            frame: CGRect(x: screen.minX + 60 + (width + 24) * 2, y: topY, width: width, height: 220),
            apps: apps,
            themeID: "dark_frost"
        )
        self.zones.append(zone3)
        
        self.autoSortRules = AutoSortRule.defaultRules
        self.license = LicenseStatus(isPro: true, activePlan: .lifetime, isMockProActive: true)
        
        // Add a starter widget right under zone 1
        let clockWidget = DesktopWidget(
            type: .clock,
            title: "Desktop Clock",
            frame: CGRect(x: screen.minX + 60, y: max(60, topY - 140), width: 220, height: 110),
            isDigitalClock: true
        )
        self.widgets.append(clockWidget)
        
        // Create a helpful welcome file in the first zone so it has instant content
        let welcomeFile = URL(fileURLWithPath: zone1.backingFolderPath).appendingPathComponent("Welcome to DesktopDüzen.txt")
        let text = "Welcome to DesktopDüzen!\n\n• Drag desktop files or Finder items directly into any zone.\n• Double-click any file to open it.\n• Press Spacebar on any selected file for instant Quick Look preview.\n• Click the chevron icon on the top right to roll up / collapse a zone.\n• Right-click any zone to customize its style with 11+ themes.\n"
        try? text.write(to: welcomeFile, atomically: true, encoding: .utf8)
        
        saveState()
    }
    
    public func exportConfigurationJSON() -> String? {
        let state = PersistedState(
            zones: zones,
            stickers: stickers,
            widgets: widgets,
            autoSortRules: autoSortRules,
            settings: settings,
            license: license
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(state), let json = String(data: data, encoding: .utf8) {
            return json
        }
        return nil
    }
    
    public func importConfigurationJSON(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data) else {
            return false
        }
        self.zones = state.zones
        self.stickers = state.stickers
        self.widgets = state.widgets
        self.autoSortRules = state.autoSortRules
        self.settings = state.settings
        self.license = state.license
        saveState()
        return true
    }
}
