import Foundation

public struct AppSettings: Codable, Equatable {
    public var launchAtLogin: Bool
    public var alignmentMode: Bool
    public var snapToGrid: Bool
    public var snapToNeighbors: Bool
    public var gridSize: CGFloat
    public var snapThreshold: CGFloat
    public var showZonesOnAllSpaces: Bool
    public var autoSortEnabled: Bool
    public var hideLooseDesktopIcons: Bool
    public var globalHotkeyEnabled: Bool
    public var hasCompletedOnboarding: Bool
    
    public init(
        launchAtLogin: Bool = false,
        alignmentMode: Bool = true,
        snapToGrid: Bool = true,
        snapToNeighbors: Bool = true,
        gridSize: CGFloat = 20.0,
        snapThreshold: CGFloat = 14.0,
        showZonesOnAllSpaces: Bool = true,
        autoSortEnabled: Bool = false,
        hideLooseDesktopIcons: Bool = false,
        globalHotkeyEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false
    ) {
        self.launchAtLogin = launchAtLogin
        self.alignmentMode = alignmentMode
        self.snapToGrid = snapToGrid
        self.snapToNeighbors = snapToNeighbors
        self.gridSize = gridSize
        self.snapThreshold = snapThreshold
        self.showZonesOnAllSpaces = showZonesOnAllSpaces
        self.autoSortEnabled = autoSortEnabled
        self.hideLooseDesktopIcons = hideLooseDesktopIcons
        self.globalHotkeyEnabled = globalHotkeyEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

public enum ProTierPlan: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case annual = "Annual"
    case lifetime = "Lifetime"
    
    public var priceString: String {
        switch self {
        case .monthly: return "$1.99 / month"
        case .annual: return "$19.99 / year"
        case .lifetime: return "$24.99 one-time"
        }
    }
    
    public var savingsBadge: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "Save 16%"
        case .lifetime: return "Best Value"
        }
    }
}

public struct LicenseStatus: Codable, Equatable {
    public var isPro: Bool
    public var activePlan: ProTierPlan?
    public var expirationDate: Date?
    public var isMockProActive: Bool
    
    public init(
        isPro: Bool = true, // By default enable Pro so the user gets all features right away, with ability to toggle in Settings
        activePlan: ProTierPlan? = .lifetime,
        expirationDate: Date? = nil,
        isMockProActive: Bool = true
    ) {
        self.isPro = isPro
        self.activePlan = activePlan
        self.expirationDate = expirationDate
        self.isMockProActive = isMockProActive
    }
}
