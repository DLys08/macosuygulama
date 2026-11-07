import Foundation
import CoreGraphics

public enum StickerType: String, Codable, CaseIterable {
    case emoji
    case sfSymbol
    case text
}

public struct DesktopSticker: Identifiable, Codable, Equatable {
    public var id: UUID
    public var type: StickerType
    public var content: String // e.g. "🚀", "star.fill", "TODO!"
    public var frame: CGRect
    public var rotationDegrees: Double
    public var scale: Double
    public var tintHex: String
    
    public init(
        id: UUID = UUID(),
        type: StickerType = .emoji,
        content: String = "⭐️",
        frame: CGRect = CGRect(x: 200, y: 200, width: 80, height: 80),
        rotationDegrees: Double = 0.0,
        scale: Double = 1.0,
        tintHex: String = "#FFCC00"
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.frame = frame
        self.rotationDegrees = rotationDegrees
        self.scale = scale
        self.tintHex = tintHex
    }
}

public enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case clock = "Clock & Date"
    case calendar = "Mini Calendar"
    case quickNote = "Sticky Note"
    case systemGlance = "System Monitor"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .clock: return "clock.fill"
        case .calendar: return "calendar"
        case .quickNote: return "note.text"
        case .systemGlance: return "gauge.medium"
        }
    }
}

public struct DesktopWidget: Identifiable, Codable, Equatable {
    public var id: UUID
    public var type: WidgetType
    public var title: String
    public var frame: CGRect
    public var noteContent: String
    public var noteColorHex: String
    public var isDigitalClock: Bool
    
    public init(
        id: UUID = UUID(),
        type: WidgetType = .clock,
        title: String = "Widget",
        frame: CGRect = CGRect(x: 300, y: 300, width: 220, height: 160),
        noteContent: String = "Don't forget to push updates!",
        noteColorHex: String = "#FFE066",
        isDigitalClock: Bool = true
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.frame = frame
        self.noteContent = noteContent
        self.noteColorHex = noteColorHex
        self.isDigitalClock = isDigitalClock
    }
}
