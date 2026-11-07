import Foundation
import AppKit
import QuickLookThumbnailing

public final class ThumbnailService {
    public static let shared = ThumbnailService()

    private let cache = NSCache<NSString, NSImage>()
    private let generator = QLThumbnailGenerator.shared

    public init() {
        cache.countLimit = 600
        cache.totalCostLimit = 64 * 1024 * 1024
    }

    /// The cache key includes the modification date, so an edited file gets a fresh thumbnail.
    private func key(for url: URL, size: CGSize, modified: Date?) -> NSString {
        let stamp = modified.map { String(Int($0.timeIntervalSince1970)) } ?? "0"
        return "\(url.path)|\(Int(size.width))x\(Int(size.height))|\(stamp)" as NSString
    }

    public func cachedThumbnail(for url: URL, size: CGSize, modified: Date?) -> NSImage? {
        cache.object(forKey: key(for: url, size: size, modified: modified))
    }

    public func thumbnail(for url: URL, size: CGSize = CGSize(width: 80, height: 80), modified: Date? = nil,
                          completion: @escaping (NSImage) -> Void) {
        let cacheKey = key(for: url, size: size, modified: modified)
        if let cached = cache.object(forKey: cacheKey) {
            completion(cached)
            return
        }
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .all)
        generator.generateBestRepresentation(for: request) { [weak self] representation, _ in
            DispatchQueue.main.async {
                let image: NSImage
                if let rep = representation {
                    image = rep.nsImage
                } else {
                    image = NSWorkspace.shared.icon(forFile: url.path)
                    image.size = size
                }
                let cost = Int(size.width * size.height * scale * scale * 4)
                self?.cache.setObject(image, forKey: cacheKey, cost: cost)
                completion(image)
            }
        }
    }

    public func appIcon(for path: String, size: CGSize = CGSize(width: 64, height: 64)) -> NSImage {
        let key = "app|\(path)|\(Int(size.width))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = size
        cache.setObject(icon, forKey: key)
        return icon
    }
}
