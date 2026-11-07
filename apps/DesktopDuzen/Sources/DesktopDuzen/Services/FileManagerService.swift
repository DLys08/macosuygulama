import Foundation
import AppKit
import UniformTypeIdentifiers

public enum NameCollisionOption {
    case keepBoth
    /// Moves the existing destination item to the Trash (recoverable) before placing the new one.
    case replace
    case skip
}

public enum TransferMode {
    case move
    case copy
}

public enum ZoneDeleteAction {
    /// Moves every item back to the Desktop; the empty zone folder goes to the Trash.
    case moveFilesToDesktop
    /// Moves the zone folder (and its contents) to the Trash, recoverable from Finder.
    case moveToTrash
    /// Removes the zone from the app only; nothing on disk changes.
    case unbindOnly
}

public struct ZoneDeleteResult: Equatable {
    public var movedCount: Int = 0
    public var failedNames: [String] = []
    public var folderRemoved: Bool = false
}

public enum FileOperationError: LocalizedError, Equatable {
    case sourceMissing(String)
    case destinationMissing(String)
    case intoItself(String)
    case nameExists(String)
    case invalidName(String)
    case system(String)

    public var errorDescription: String? {
        switch self {
        case .sourceMissing(let n): return "“\(n)” no longer exists."
        case .destinationMissing(let n): return "The destination folder “\(n)” is not available."
        case .intoItself(let n): return "“\(n)” cannot be moved into itself."
        case .nameExists(let n): return "An item named “\(n)” already exists."
        case .invalidName(let n): return "“\(n)” is not a valid file name."
        case .system(let message): return message
        }
    }
}

public final class FileManagerService {
    public static let shared = FileManagerService()

    private let fileManager = FileManager.default
    public let desktopURL: URL

    /// - Parameter desktopURL: injectable for tests; defaults to the user's real Desktop.
    public init(desktopURL: URL? = nil) {
        if let custom = desktopURL {
            self.desktopURL = custom
        } else {
            self.desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop", isDirectory: true)
        }
    }

    /// Moves an item to the Trash. Injectable so tests never touch the user's real Trash.
    public var trashHandler: (URL) throws -> Void = { url in
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }

    public var zonesBaseURL: URL {
        desktopURL.appendingPathComponent("Zones", isDirectory: true)
    }

    public func folderExists(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return !path.isEmpty && fileManager.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    // MARK: - Zone folders

    /// Returns the folder for a File Zone.
    /// - Parameter reuseExisting: when true, an existing folder with the exact name is reused
    ///   instead of creating "Name 1", "Name 2", ... This keeps repeated first-run setups idempotent.
    public func createFolderForFileZone(title: String, reuseExisting: Bool = false) -> URL? {
        do {
            try fileManager.createDirectory(at: zonesBaseURL, withIntermediateDirectories: true)
        } catch {
            NSLog("DesktopDuzen: cannot create Zones folder: \(error.localizedDescription)")
            return nil
        }
        let sanitized = sanitizeFolderName(title)
        var targetURL = zonesBaseURL.appendingPathComponent(sanitized, isDirectory: true)
        if reuseExisting && folderExists(targetURL.path) {
            return targetURL
        }
        var counter = 1
        while fileManager.fileExists(atPath: targetURL.path) {
            targetURL = zonesBaseURL.appendingPathComponent("\(sanitized) \(counter)", isDirectory: true)
            counter += 1
        }
        do {
            try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
            return targetURL
        } catch {
            NSLog("DesktopDuzen: cannot create zone folder: \(error.localizedDescription)")
            return nil
        }
    }

    public func renameZoneFolder(oldPath: String, newTitle: String) -> String? {
        let oldURL = URL(fileURLWithPath: oldPath)
        guard folderExists(oldURL.path) else { return nil }
        let parent = oldURL.deletingLastPathComponent()
        let sanitized = sanitizeFolderName(newTitle)
        var newURL = parent.appendingPathComponent(sanitized, isDirectory: true)
        if newURL.standardizedFileURL.path == oldURL.standardizedFileURL.path { return oldPath }
        // Case-only rename on a case-insensitive volume.
        if newURL.path.lowercased() == oldURL.path.lowercased() {
            let temp = parent.appendingPathComponent(".dd-rename-\(UUID().uuidString)", isDirectory: true)
            do {
                try fileManager.moveItem(at: oldURL, to: temp)
                try fileManager.moveItem(at: temp, to: newURL)
                return newURL.path
            } catch {
                if fileManager.fileExists(atPath: temp.path) { try? fileManager.moveItem(at: temp, to: oldURL) }
                return nil
            }
        }
        var counter = 1
        while fileManager.fileExists(atPath: newURL.path) {
            newURL = parent.appendingPathComponent("\(sanitized) \(counter)", isDirectory: true)
            counter += 1
        }
        do {
            try fileManager.moveItem(at: oldURL, to: newURL)
            return newURL.path
        } catch {
            NSLog("DesktopDuzen: error renaming zone folder: \(error.localizedDescription)")
            return nil
        }
    }

    /// Never permanently deletes user files: folders go to the Trash, and only when empty
    /// for the "move back to Desktop" path.
    @discardableResult
    public func deleteZone(folderPath: String, action: ZoneDeleteAction) -> ZoneDeleteResult {
        var result = ZoneDeleteResult()
        let folderURL = URL(fileURLWithPath: folderPath)
        guard folderExists(folderURL.path) else { return result }

        switch action {
        case .moveFilesToDesktop:
            let items = (try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [])) ?? []
            for item in items where item.lastPathComponent != ".DS_Store" {
                switch transfer(item, toDirectory: desktopURL, mode: .move, collision: .keepBoth) {
                case .success: result.movedCount += 1
                case .failure: result.failedNames.append(item.lastPathComponent)
                }
            }
            if isEffectivelyEmpty(folderURL) {
                result.folderRemoved = (try? trashHandler(folderURL)) != nil
            }
        case .moveToTrash:
            result.folderRemoved = (try? trashHandler(folderURL)) != nil
        case .unbindOnly:
            break
        }
        return result
    }

    public func isEffectivelyEmpty(_ folder: URL) -> Bool {
        let items = (try? fileManager.contentsOfDirectory(atPath: folder.path)) ?? []
        return items.allSatisfy { $0 == ".DS_Store" }
    }

    // MARK: - Listing

    public func contentsOfFolder(path: String, manualOrder: [String] = []) -> [FileItem] {
        let folderURL = URL(fileURLWithPath: path)
        guard folderExists(folderURL.path) else { return [] }
        let keys: [URLResourceKey] = [.nameKey, .isDirectoryKey, .isPackageKey, .fileSizeKey,
                                      .contentModificationDateKey, .localizedTypeDescriptionKey]
        guard let urls = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) else {
            return []
        }
        var orderLookup: [String: Int] = [:]
        for (index, name) in manualOrder.enumerated() where orderLookup[name] == nil { orderLookup[name] = index }

        return urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            let name = values?.name ?? url.lastPathComponent
            let isDir = (values?.isDirectory ?? false) && !(values?.isPackage ?? false)
            return FileItem(
                name: name,
                url: url,
                isDirectory: isDir,
                size: Int64(values?.fileSize ?? 0),
                modificationDate: values?.contentModificationDate ?? Date.distantPast,
                kindDescription: values?.localizedTypeDescription ?? (isDir ? "Folder" : "Document"),
                manualOrder: orderLookup[name] ?? Int.max
            )
        }
    }

    // MARK: - Transfers

    public func isSameVolume(_ a: URL, _ b: URL) -> Bool {
        let va = (try? a.resourceValues(forKeys: [.volumeIdentifierKey]))?.volumeIdentifier as? NSObject
        let vb = (try? b.resourceValues(forKeys: [.volumeIdentifierKey]))?.volumeIdentifier as? NSObject
        guard let left = va, let right = vb else { return true }
        return left.isEqual(right)
    }

    /// Moves or copies one item into `destDir`, resolving name collisions without overwriting.
    public func transfer(_ sourceURL: URL, toDirectory destDir: URL, mode: TransferMode,
                         collision: NameCollisionOption = .keepBoth) -> Result<URL, FileOperationError> {
        let source = sourceURL.standardizedFileURL
        let dest = destDir.standardizedFileURL
        guard fileManager.fileExists(atPath: source.path) else { return .failure(.sourceMissing(source.lastPathComponent)) }
        guard folderExists(dest.path) else { return .failure(.destinationMissing(dest.lastPathComponent)) }
        if dest.path == source.path || dest.path.hasPrefix(source.path + "/") {
            return .failure(.intoItself(source.lastPathComponent))
        }
        if mode == .move && source.deletingLastPathComponent().path == dest.path {
            return .success(source) // Already there; nothing to do.
        }

        let fileName = source.lastPathComponent
        var targetURL = dest.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: targetURL.path) {
            switch collision {
            case .skip:
                return .failure(.nameExists(fileName))
            case .replace:
                do { try trashHandler(targetURL) }
                catch { return .failure(.system(error.localizedDescription)) }
            case .keepBoth:
                targetURL = uniqueURL(in: dest, for: fileName, suffix: nil)
            }
        }
        do {
            switch mode {
            case .move: try fileManager.moveItem(at: source, to: targetURL)
            case .copy: try fileManager.copyItem(at: source, to: targetURL)
            }
            return .success(targetURL)
        } catch {
            return .failure(.system(error.localizedDescription))
        }
    }

    /// Backwards-compatible convenience used by older call sites and tests.
    public func moveFile(from sourceURL: URL, toDirectory destDir: URL, collisionOption: NameCollisionOption = .keepBoth) -> URL? {
        try? transfer(sourceURL, toDirectory: destDir, mode: .move, collision: collisionOption).get()
    }

    /// Creates "name copy.ext" (then "name copy 2.ext", ...) next to the original.
    public func duplicateFile(at url: URL) -> Result<URL, FileOperationError> {
        guard fileManager.fileExists(atPath: url.path) else { return .failure(.sourceMissing(url.lastPathComponent)) }
        let target = uniqueURL(in: url.deletingLastPathComponent(), for: url.lastPathComponent, suffix: "copy")
        do {
            try fileManager.copyItem(at: url, to: target)
            return .success(target)
        } catch {
            return .failure(.system(error.localizedDescription))
        }
    }

    public func uniqueURL(in dir: URL, for fileName: String, suffix: String?) -> URL {
        let ext = (fileName as NSString).pathExtension
        let base = (fileName as NSString).deletingPathExtension
        func make(_ n: Int) -> URL {
            var stem: String
            if let suffix = suffix {
                stem = n <= 1 ? "\(base) \(suffix)" : "\(base) \(suffix) \(n)"
            } else {
                stem = "\(base) \(n)"
            }
            return dir.appendingPathComponent(ext.isEmpty ? stem : "\(stem).\(ext)")
        }
        var n = 1
        var candidate = make(n)
        while fileManager.fileExists(atPath: candidate.path) {
            n += 1
            candidate = make(n)
        }
        return candidate
    }

    public func trashFile(url: URL) -> Bool {
        do {
            try trashHandler(url)
            return true
        } catch {
            NSLog("DesktopDuzen: failed to trash file: \(error.localizedDescription)")
            return false
        }
    }

    public func renameFile(at url: URL, to newName: String) -> Result<URL, FileOperationError> {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("/"), !trimmed.contains(":"), trimmed != ".", trimmed != ".." else {
            return .failure(.invalidName(newName))
        }
        let dest = url.deletingLastPathComponent().appendingPathComponent(trimmed)
        if dest.path == url.path { return .success(url) }
        if fileManager.fileExists(atPath: dest.path) && dest.path.lowercased() != url.path.lowercased() {
            return .failure(.nameExists(trimmed))
        }
        do {
            try fileManager.moveItem(at: url, to: dest)
            return .success(dest)
        } catch {
            return .failure(.system(error.localizedDescription))
        }
    }

    // MARK: - App helpers

    public func resolveAppInfo(at path: String) -> AppItem? {
        let url = URL(fileURLWithPath: path)
        guard fileManager.fileExists(atPath: path), isApplication(at: url) else { return nil }
        let bundle = Bundle(url: url)
        let name = bundle?.infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle?.infoDictionary?["CFBundleName"] as? String
            ?? url.deletingPathExtension().lastPathComponent
        return AppItem(name: name, bundleID: bundle?.bundleIdentifier ?? "", path: path)
    }

    public func isApplication(at url: URL) -> Bool {
        if url.pathExtension.lowercased() == "app" { return true }
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type.conforms(to: .application)
        }
        return false
    }

    // MARK: - Utilities

    public func sanitizeFolderName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        var cleaned = name.components(separatedBy: invalidChars).joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        while cleaned.hasPrefix(".") { cleaned.removeFirst() }
        return cleaned.isEmpty ? "Zone" : cleaned
    }

    public func createSecurityBookmark(for url: URL) -> Data? {
        // The app is not sandboxed, so a plain bookmark is enough to follow moved folders.
        try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    /// Resolves a bookmark to the folder's current path (follows renames/moves).
    public func resolveBookmark(data: Data) -> URL? {
        var isStale = false
        return try? URL(resolvingBookmarkData: data, options: [.withoutUI, .withoutMounting],
                        relativeTo: nil, bookmarkDataIsStale: &isStale)
    }
}
