import Foundation
import AppKit
import QuickLookThumbnailing

public class ThumbnailService {
    public static let shared = ThumbnailService()
    
    private let cache = NSCache<NSString, NSImage>()
    private let generator = QLThumbnailGenerator.shared
    
    public init() {
        cache.countLimit = 400
    }
    
    public func thumbnail(for url: URL, size: CGSize = CGSize(width: 80, height: 80), completion: @escaping (NSImage) -> Void) {
        let cacheKey = "\(url.path)_\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            completion(cached)
            return
        }
        
        let fallbackIcon = NSWorkspace.shared.icon(forFile: url.path)
        fallbackIcon.size = size
        
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )
        
        generator.generateBestRepresentation(for: request) { [weak self] representation, error in
            DispatchQueue.main.async {
                if let rep = representation {
                    let image = rep.nsImage
                    self?.cache.setObject(image, forKey: cacheKey)
                    completion(image)
                } else {
                    self?.cache.setObject(fallbackIcon, forKey: cacheKey)
                    completion(fallbackIcon)
                }
            }
        }
    }
    
    public func appIcon(for path: String, size: CGSize = CGSize(width: 64, height: 64)) -> NSImage {
        let key = "app_\(path)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = size
        cache.setObject(icon, forKey: key)
        return icon
    }
}
