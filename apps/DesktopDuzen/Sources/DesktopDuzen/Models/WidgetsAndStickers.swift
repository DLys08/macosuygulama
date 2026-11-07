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
    public var content: String
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

    enum CodingKeys: String, CodingKey { case id, type, content, frame, rotationDegrees, scale, tintHex }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        type = c.value(.type, default: .emoji)
        content = c.value(.content, default: "⭐️")
        frame = c.value(.frame, default: CGRect(x: 200, y: 200, width: 80, height: 80))
        rotationDegrees = c.value(.rotationDegrees, default: 0)
        scale = min(max(c.value(.scale, default: 1.0), 0.3), 4)
        tintHex = c.value(.tintHex, default: "#FFCC00")
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

    public var defaultSize: CGSize {
        switch self {
        case .clock: return CGSize(width: 220, height: 120)
        case .calendar: return CGSize(width: 240, height: 230)
        case .quickNote: return CGSize(width: 230, height: 190)
        case .systemGlance: return CGSize(width: 230, height: 150)
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
    /// Theme (same library as zones). Default matches the original dark glass look.
    public var themeID: String
    /// nil = theme opacity; below 0.35 the widget is drawn in clear mode.
    public var backgroundOpacity: Double?
    public var showBorder: Bool

    public init(
        id: UUID = UUID(),
        type: WidgetType = .clock,
        title: String = "Widget",
        frame: CGRect = CGRect(x: 300, y: 300, width: 220, height: 160),
        noteContent: String = "",
        noteColorHex: String = "#FFE066",
        isDigitalClock: Bool = true,
        themeID: String = "dark_frost",
        backgroundOpacity: Double? = nil,
        showBorder: Bool = true
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.frame = frame
        self.noteContent = noteContent
        self.noteColorHex = noteColorHex
        self.isDigitalClock = isDigitalClock
        self.themeID = themeID
        self.backgroundOpacity = backgroundOpacity
        self.showBorder = showBorder
    }

    enum CodingKeys: String, CodingKey {
        case id, type, title, frame, noteContent, noteColorHex, isDigitalClock, themeID, backgroundOpacity, showBorder
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        type = c.value(.type, default: .clock)
        title = c.value(.title, default: "Widget")
        var f = c.value(.frame, default: CGRect(x: 300, y: 300, width: 220, height: 160))
        if f.width < 140 { f.size.width = 140 }
        if f.height < 90 { f.size.height = 90 }
        frame = f
        noteContent = c.value(.noteContent, default: "")
        noteColorHex = c.value(.noteColorHex, default: "#FFE066")
        isDigitalClock = c.value(.isDigitalClock, default: true)
        themeID = c.value(.themeID, default: "dark_frost")
        let opacity: Double? = c.optionalValue(.backgroundOpacity)
        backgroundOpacity = opacity.map { min(max($0, 0), 1) }
        showBorder = c.value(.showBorder, default: true)
    }
}
