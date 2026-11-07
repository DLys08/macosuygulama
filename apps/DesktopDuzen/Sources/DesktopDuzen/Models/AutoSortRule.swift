import Foundation

public struct AutoSortRule: Identifiable, Codable, Equatable {
    public var id: UUID
    public var isEnabled: Bool
    public var name: String
    /// Used when `targetZoneID` is nil or no longer exists; matched case-insensitively.
    public var targetZoneTitle: String
    public var targetZoneID: UUID?
    public var extensions: [String]

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
        self.extensions = AutoSortRule.normalize(extensions)
    }

    enum CodingKeys: String, CodingKey { case id, isEnabled, name, targetZoneTitle, targetZoneID, extensions }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(.id, default: UUID())
        isEnabled = c.value(.isEnabled, default: true)
        name = c.value(.name, default: "Rule")
        targetZoneTitle = c.value(.targetZoneTitle, default: "")
        targetZoneID = c.optionalValue(.targetZoneID)
        extensions = AutoSortRule.normalize(c.value(.extensions, default: []))
    }

    /// Lowercases, strips leading dots and whitespace, removes empties and duplicates.
    public static func normalize(_ list: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in list {
            var ext = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            while ext.hasPrefix(".") { ext.removeFirst() }
            if !ext.isEmpty && !seen.contains(ext) {
                seen.insert(ext)
                result.append(ext)
            }
        }
        return result
    }

    public static func parseExtensions(_ text: String) -> [String] {
        normalize(text.components(separatedBy: CharacterSet(charactersIn: ", ;")))
    }

    public func matches(extension ext: String) -> Bool {
        extensions.contains(ext.lowercased())
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
            extensions: ["pdf", "docx", "doc", "txt", "pages", "numbers", "key", "keynote", "xlsx", "csv", "md"]
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
