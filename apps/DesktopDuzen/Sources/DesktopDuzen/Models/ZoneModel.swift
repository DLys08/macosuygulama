import Foundation
import CoreGraphics

public struct ZoneModel: Identifiable, Codable, Equatable {
    public var id: UUID
    public var type: ZoneType
    public var title: String
    public var frame: CGRect
    public var displayID: UInt32
    public var isCollapsed: Bool
    public var collapsedHeight: CGFloat
    public var expandedHeight: CGFloat
    public var autoExpandOnHover: Bool
    public var isPinnedOnTop: Bool
    public var viewMode: ZoneViewMode
    public var sortMode: ZoneSortMode
    public var tabs: [ZoneTab]
    public var activeTabID: UUID?
    public var apps: [AppItem]
    public var backingFolderPath: String
    public var securityBookmarkData: Data?
    public var themeID: String
    public var iconSize: Double
    public var fontSize: Double
    public var iconSpacing: Double
    public var manualOrder: [String]
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        type: ZoneType = .file,
        title: String,
        frame: CGRect = CGRect(x: 100, y: 100, width: 340, height: 260),
        displayID: UInt32 = 0,
        isCollapsed: Bool = false,
        collapsedHeight: CGFloat = 42.0,
        expandedHeight: CGFloat = 260.0,
        autoExpandOnHover: Bool = false,
        isPinnedOnTop: Bool = false,
        viewMode: ZoneViewMode = .icon,
        sortMode: ZoneSortMode = .manual,
        tabs: [ZoneTab] = [],
        activeTabID: UUID? = nil,
        apps: [AppItem] = [],
        backingFolderPath: String = "",
        securityBookmarkData: Data? = nil,
        themeID: String = "glass_blur",
        iconSize: Double = 52.0,
        fontSize: Double = 11.5,
        iconSpacing: Double = 12.0,
        manualOrder: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.frame = frame
        self.displayID = displayID
        self.isCollapsed = isCollapsed
        self.collapsedHeight = collapsedHeight
        self.expandedHeight = expandedHeight
        self.autoExpandOnHover = autoExpandOnHover
        self.isPinnedOnTop = isPinnedOnTop
        self.viewMode = viewMode
        self.sortMode = sortMode
        self.tabs = tabs
        self.activeTabID = activeTabID
        self.apps = apps
        self.backingFolderPath = backingFolderPath
        self.securityBookmarkData = securityBookmarkData
        self.themeID = themeID
        self.iconSize = iconSize
        self.fontSize = fontSize
        self.iconSpacing = iconSpacing
        self.manualOrder = manualOrder
        self.createdAt = createdAt
    }
    
    public var resolvedFolderPath: String {
        if type == .app { return "" }
        if !tabs.isEmpty, let activeID = activeTabID, let tab = tabs.first(where: { $0.id == activeID }) {
            let subfolder = (backingFolderPath as NSString).appendingPathComponent(tab.subfolderName)
            return subfolder
        }
        return backingFolderPath
    }
}
