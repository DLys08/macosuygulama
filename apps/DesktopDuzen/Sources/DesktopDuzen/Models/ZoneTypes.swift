import Foundation
import SwiftUI

public enum ZoneType: String, Codable, CaseIterable, Identifiable {
    case file = "File Zone"
    case folder = "Folder Zone"
    case app = "App Zone"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .file: return "folder.fill"
        case .folder: return "folder.badge.gearshape"
        case .app: return "square.grid.2x2.fill"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .file: return "Moves desktop clutter into a dedicated folder"
        case .folder: return "Quick access mirror of any folder on your Mac"
        case .app: return "1-click app launcher right from your desktop"
        }
    }
}

public enum ZoneViewMode: String, Codable, CaseIterable {
    case icon = "Icon"
    case list = "List"
    
    public var iconName: String {
        switch self {
        case .icon: return "square.grid.3x3"
        case .list: return "list.bullet"
        }
    }
}

public enum ZoneSortMode: String, Codable, CaseIterable {
    case manual = "Manual (Drag to Sort)"
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case dateDesc = "Date (Newest First)"
    case dateAsc = "Date (Oldest First)"
    case sizeDesc = "Size (Largest First)"
    case sizeAsc = "Size (Smallest First)"
    case kind = "Kind"
    
    public var systemImage: String {
        switch self {
        case .manual: return "hand.draw"
        case .nameAsc: return "arrow.up.circle"
        case .nameDesc: return "arrow.down.circle"
        case .dateDesc: return "clock.arrow.circlepath"
        case .dateAsc: return "clock"
        case .sizeDesc: return "arrow.down.right.and.arrow.up.left"
        case .sizeAsc: return "arrow.up.left.and.arrow.down.right"
        case .kind: return "doc.on.doc"
        }
    }
}

public struct ZoneTab: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var subfolderName: String
    public var order: Int
    
    public init(id: UUID = UUID(), title: String, subfolderName: String? = nil, order: Int = 0) {
        self.id = id
        self.title = title
        self.subfolderName = subfolderName ?? title
        self.order = order
    }
}

public struct AppItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var bundleID: String
    public var path: String
    public var order: Int
    
    public init(id: UUID = UUID(), name: String, bundleID: String = "", path: String, order: Int = 0) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.path = path
        self.order = order
    }
}

public struct FileItem: Identifiable, Equatable, Hashable {
    public var id: String { path }
    public var name: String
    public var url: URL
    public var path: String
    public var isDirectory: Bool
    public var size: Int64
    public var modificationDate: Date
    public var kindDescription: String
    public var manualOrder: Int
    
    public init(
        name: String,
        url: URL,
        isDirectory: Bool = false,
        size: Int64 = 0,
        modificationDate: Date = Date(),
        kindDescription: String = "File",
        manualOrder: Int = 0
    ) {
        self.name = name
        self.url = url
        self.path = url.path
        self.isDirectory = isDirectory
        self.size = size
        self.modificationDate = modificationDate
        self.kindDescription = kindDescription
        self.manualOrder = manualOrder
    }
    
    public var formattedSize: String {
        if isDirectory { return "--" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }
}
