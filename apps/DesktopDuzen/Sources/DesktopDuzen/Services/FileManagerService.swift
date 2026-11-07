import Foundation
import AppKit
import QuickLookThumbnailing
import UniformTypeIdentifiers

public enum NameCollisionOption {
    case keepBoth
    case replace
    case skip
}

public enum ZoneDeleteAction {
    case moveFilesToDesktop
    case moveToTrash
    case unbindOnly
}

public class FileManagerService {
    public static let shared = FileManagerService()
    
    private let fileManager = FileManager.default
    
    public var desktopURL: URL {
        fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory().appending("/Desktop"))
    }
    
    public var zonesBaseURL: URL {
        desktopURL.appendingPathComponent("Zones", isDirectory: true)
    }
    
    public init() {
        try? fileManager.createDirectory(at: zonesBaseURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Zone Folder Creation & Management
    
    public func createFolderForFileZone(title: String) -> URL {
        let sanitized = sanitizeFolderName(title)
        var targetURL = zonesBaseURL.appendingPathComponent(sanitized, isDirectory: true)
        
        var counter = 1
        while fileManager.fileExists(atPath: targetURL.path) {
            targetURL = zonesBaseURL.appendingPathComponent("\(sanitized) \(counter)", isDirectory: true)
            counter += 1
        }
        
        try? fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
        return targetURL
    }
    
    public func renameZoneFolder(oldPath: String, newTitle: String) -> String? {
        let oldURL = URL(fileURLWithPath: oldPath)
        guard fileManager.fileExists(atPath: oldURL.path) else { return nil }
        
        let parent = oldURL.deletingLastPathComponent()
        let sanitized = sanitizeFolderName(newTitle)
        var newURL = parent.appendingPathComponent(sanitized, isDirectory: true)
        
        if newURL.path == oldURL.path { return oldPath }
        
        var counter = 1
        while fileManager.fileExists(atPath: newURL.path) {
            newURL = parent.appendingPathComponent("\(sanitized) \(counter)", isDirectory: true)
            counter += 1
        }
        
        do {
            try fileManager.moveItem(at: oldURL, to: newURL)
            return newURL.path
        } catch {
            print("Error renaming zone folder: \(error)")
            return nil
        }
    }
    
    public func deleteZone(folderPath: String, action: ZoneDeleteAction) {
        let folderURL = URL(fileURLWithPath: folderPath)
        guard fileManager.fileExists(atPath: folderURL.path) else { return }
        
        switch action {
        case .moveFilesToDesktop:
            if let files = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for file in files {
                    _ = moveFile(from: file, toDirectory: desktopURL, collisionOption: .keepBoth)
                }
            }
            try? fileManager.removeItem(at: folderURL)
            
        case .moveToTrash:
            try? fileManager.trashItem(at: folderURL, resultingItemURL: nil)
            
        case .unbindOnly:
            // Do not delete folder from disk
            break
        }
    }
    
    // MARK: - File Listing
    
    public func contentsOfFolder(path: String, manualOrder: [String] = []) -> [FileItem] {
        let folderURL = URL(fileURLWithPath: path)
        guard fileManager.fileExists(atPath: folderURL.path) else { return [] }
        
        let keys: [URLResourceKey] = [.nameKey, .isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .localizedTypeDescriptionKey]
        
        guard let urls = try? fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        var items: [FileItem] = []
        
        for url in urls {
            let values = try? url.resourceValues(forKeys: Set(keys))
            let name = values?.name ?? url.lastPathComponent
            let isDir = values?.isDirectory ?? false
            let size = Int64(values?.fileSize ?? 0)
            let modDate = values?.contentModificationDate ?? Date()
            let kind = values?.localizedTypeDescription ?? (isDir ? "Folder" : "Document")
            
            let orderIndex = manualOrder.firstIndex(of: name) ?? 999999
            
            let item = FileItem(
                name: name,
                url: url,
                isDirectory: isDir,
                size: size,
                modificationDate: modDate,
                kindDescription: kind,
                manualOrder: orderIndex
            )
            items.append(item)
        }
        
        return items
    }
    
    // MARK: - File Operations (Move, Copy, Collision)
    
    public func moveFile(from sourceURL: URL, toDirectory destDir: URL, collisionOption: NameCollisionOption = .keepBoth) -> URL? {
        guard fileManager.fileExists(atPath: sourceURL.path) else { return nil }
        
        let fileName = sourceURL.lastPathComponent
        var targetURL = destDir.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: targetURL.path) {
            switch collisionOption {
            case .skip:
                return nil
            case .replace:
                try? fileManager.removeItem(at: targetURL)
            case .keepBoth:
                let ext = sourceURL.pathExtension
                let baseName = (fileName as NSString).deletingPathExtension
                var counter = 1
                repeat {
                    let newName = ext.isEmpty ? "\(baseName) \(counter)" : "\(baseName) \(counter).\(ext)"
                    targetURL = destDir.appendingPathComponent(newName)
                    counter += 1
                } while fileManager.fileExists(atPath: targetURL.path)
            }
        }
        
        do {
            try fileManager.moveItem(at: sourceURL, to: targetURL)
            return targetURL
        } catch {
            print("Failed to move file from \(sourceURL) to \(targetURL): \(error)")
            // Fallback: try copy + delete if moving across volumes
            do {
                try fileManager.copyItem(at: sourceURL, to: targetURL)
                try? fileManager.removeItem(at: sourceURL)
                return targetURL
            } catch {
                print("Failed fallback copy: \(error)")
                return nil
            }
        }
    }
    
    public func trashFile(url: URL) -> Bool {
        do {
            try fileManager.trashItem(at: url, resultingItemURL: nil)
            return true
        } catch {
            print("Failed to trash file: \(error)")
            return false
        }
    }
    
    public func renameFile(at url: URL, to newName: String) -> URL? {
        let dest = url.deletingLastPathComponent().appendingPathComponent(newName)
        if dest.path == url.path { return url }
        do {
            try fileManager.moveItem(at: url, to: dest)
            return dest
        } catch {
            print("Failed to rename file: \(error)")
            return nil
        }
    }
    
    // MARK: - App Zone Helpers
    
    public func resolveAppInfo(at path: String) -> AppItem? {
        let url = URL(fileURLWithPath: path)
        guard url.pathExtension.lowercased() == "app" || isApplication(at: url) else { return nil }
        
        let bundle = Bundle(url: url)
        let name = bundle?.infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle?.infoDictionary?["CFBundleName"] as? String
            ?? (url.deletingPathExtension().lastPathComponent)
        let bundleID = bundle?.bundleIdentifier ?? ""
        
        return AppItem(name: name, bundleID: bundleID, path: path)
    }
    
    public func isApplication(at url: URL) -> Bool {
        if url.pathExtension.lowercased() == "app" { return true }
        if let val = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let type = val.contentType {
            return type.conforms(to: .application)
        }
        return false
    }
    
    // MARK: - Utilities
    
    public func sanitizeFolderName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = name.components(separatedBy: invalidChars).joined(separator: "-").trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Zone" : cleaned
    }
    
    public func createSecurityBookmark(for url: URL) -> Data? {
        try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
    
    public func resolveSecurityBookmark(data: Data) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }
        
        _ = url.startAccessingSecurityScopedResource()
        return url
    }
}
