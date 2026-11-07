import Foundation

public struct AutoSortRule: Identifiable, Codable, Equatable {
    public var id: UUID
    public var isEnabled: Bool
    public var name: String
    public var targetZoneTitle: String
    public var targetZoneID: UUID?
    public var extensions: [String] // e.g. ["png", "jpg", "jpeg", "heic", "gif"]
    
    public init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        name: String,
        targetZoneTitle: String,
        targetZoneID: UUID? = nil,
        extensions: [String]
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.name = name
        self.targetZoneTitle = targetZoneTitle
        self.targetZoneID = targetZoneID
        self.extensions = extensions
    }
    
    public static let defaultRules: [AutoSortRule] = [
        AutoSortRule(
            name: "Images & Screenshots",
            targetZoneTitle: "Media & Images",
            extensions: ["png", "jpg", "jpeg", "heic", "gif", "svg", "webp"]
        ),
        AutoSortRule(
            name: "Documents & PDFs",
            targetZoneTitle: "Documents",
            extensions: ["pdf", "docx", "doc", "txt", "pages", "numbers", "keynote", "xlsx", "csv", "md"]
        ),
        AutoSortRule(
            name: "Archives & Installers",
            targetZoneTitle: "Downloads & Installers",
            extensions: ["dmg", "pkg", "zip", "tar", "gz", "7z", "iso"]
        ),
        AutoSortRule(
            name: "Audio & Video",
            targetZoneTitle: "Audio & Video",
            extensions: ["mp4", "mov", "m4v", "mp3", "wav", "m4a", "flac"]
        )
    ]
}
