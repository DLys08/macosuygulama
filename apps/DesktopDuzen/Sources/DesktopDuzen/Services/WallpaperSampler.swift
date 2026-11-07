import AppKit
import Combine

/// Measures how light the desktop wallpaper is behind a given screen rectangle, so transparent
/// ("clear") zones can use black text on light wallpaper and white text on dark wallpaper.
/// Each display's wallpaper is decoded once into a tiny bitmap, off the main thread.
public final class WallpaperSampler: ObservableObject {
    public static let shared = WallpaperSampler()

    /// Bumped whenever a wallpaper finishes loading or changes; views observe it to re-render.
    @Published public private(set) var version = 0

    private struct Sample {
        let url: URL
        let screenFrame: CGRect
        let width: Int
        let height: Int
        let luminance: [Double] // row-major, row 0 = top
    }

    private var samples: [CGDirectDisplayID: Sample] = [:]
    private var loading: Set<URL> = []
    private let queue = DispatchQueue(label: "com.desktopduzen.wallpaper", qos: .utility)
    private var timer: Timer?
    private static let gridWidth = 96

    public init() {
        let ws = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didWakeNotification] {
            ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
        // No notification exists for wallpaper changes; a cheap periodic check covers it.
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in self?.refresh() }
        timer?.tolerance = 5
        refresh()
    }

    private func displayID(_ screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    /// What macOS is drawing on a display.
    enum Source: Equatable {
        case solid(Double)   // relative luminance
        case image(URL)
    }

    private static let placeholderPath = "/System/Library/CoreServices/DefaultDesktop.heic"
    private static var storeURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.wallpaper/Store/Index.plist")
    }

    public func refresh() {
        let store = WallpaperSampler.readStore()
        for screen in NSScreen.screens {
            guard let id = displayID(screen) else { continue }
            let uuid = CGDisplayCreateUUIDFromDisplayID(id).map { CFUUIDCreateString(nil, $0.takeRetainedValue()) as String }
            var source = store.flatMap { WallpaperSampler.source(inStore: $0, displayUUID: uuid) }
            if source == nil, let url = NSWorkspace.shared.desktopImageURL(for: screen), url.path != WallpaperSampler.placeholderPath {
                source = .image(url)
            }
            switch source {
            case .solid(let lum):
                let marker = URL(fileURLWithPath: "/solid/\(lum)")
                if let existing = samples[id], existing.url == marker, existing.screenFrame == screen.frame { continue }
                samples[id] = Sample(url: marker, screenFrame: screen.frame, width: 1, height: 1, luminance: [lum])
                version += 1
            case .image(let url):
                if let existing = samples[id], existing.url == url, existing.screenFrame == screen.frame { continue }
                load(url: url, screenFrame: screen.frame, displayID: id)
            case nil:
                // Unknown (e.g. animated/aerial wallpaper): fall back to white text with a dark shadow.
                if samples.removeValue(forKey: id) != nil { version += 1 }
            }
        }
    }

    private static func readStore() -> [String: Any]? {
        guard let data = try? Data(contentsOf: storeURL) else { return nil }
        return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
    }

    /// Parses the macOS wallpaper store (Sonoma and later) for one display. Internal for tests.
    static func source(inStore store: [String: Any], displayUUID: String?) -> Source? {
        func choice(_ entry: Any?) -> [String: Any]? {
            guard let e = entry as? [String: Any] else { return nil }
            for key in ["Linked", "Desktop"] {
                if let content = (e[key] as? [String: Any])?["Content"] as? [String: Any],
                   let first = (content["Choices"] as? [[String: Any]])?.first { return first }
            }
            return nil
        }
        let displays = store["Displays"] as? [String: Any]
        let entry = (displayUUID.flatMap { displays?[$0] }).flatMap(choice)
            ?? choice(store["AllSpacesAndDisplays"]) ?? choice(store["SystemDefault"])
        guard let pick = entry, let provider = pick["Provider"] as? String else { return nil }

        if provider.hasSuffix("choice.color") {
            guard let data = pick["Configuration"] as? Data,
                  let config = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any] else { return nil }
            return solidLuminance(config).map { .solid($0) }
        }
        if provider.hasSuffix("choice.image") || provider.contains("image") {
            for file in (pick["Files"] as? [Any]) ?? [] {
                if let str = (file as? [String: Any])?["relative"] as? String ?? file as? String,
                   let url = URL(string: str), url.isFileURL || str.hasPrefix("/") {
                    return .image(url.isFileURL ? url : URL(fileURLWithPath: str))
                }
            }
        }
        return nil
    }

    /// Luminance of a solid wallpaper colour from its store configuration.
    static func solidLuminance(_ config: [String: Any]) -> Double? {
        // Explicit components anywhere in the configuration.
        func components(_ any: Any) -> [Double]? {
            if let a = any as? [Double], a.count >= 3 { return a }
            if let a = any as? [NSNumber], a.count >= 3 { return a.map { $0.doubleValue } }
            if let d = any as? [String: Any] {
                if let r = (d["red"] as? NSNumber)?.doubleValue, let g = (d["green"] as? NSNumber)?.doubleValue,
                   let b = (d["blue"] as? NSNumber)?.doubleValue { return [r, g, b] }
                for v in d.values { if let c = components(v) { return c } }
            }
            return nil
        }
        if let c = components(config) {
            return RGBAColor(r: c[0], g: c[1], b: c[2]).relativeLuminance
        }
        // Named system colours (keys are the colour name).
        let known: [String: String] = [
            "black": "#000000", "white": "#FFFFFF", "silver": "#C6C7C8", "spaceGray": "#3B3C3E",
            "spaceGrayPro": "#2E2F31", "gold": "#E5D2BC", "roseGold": "#E8C5C1", "stone": "#9A9A97",
            "teal": "#1C5E6A", "tealDark": "#173E46", "navy": "#1D2B4C", "blue": "#2C5CA8",
            "purple": "#5B3F86", "red": "#9E2A2B", "orange": "#C46A2E", "yellow": "#D8B13A", "green": "#3E7A43"
        ]
        if let named = config["systemColor"] as? [String: Any] {
            for name in named.keys {
                if let hex = known[name] { return RGBAColor(hex: hex).relativeLuminance }
                let lower = name.lowercased()
                if lower.contains("black") || lower.contains("dark") { return 0.02 }
                if lower.contains("white") || lower.contains("light") { return 0.9 }
            }
        }
        return nil
    }

    private func load(url: URL, screenFrame: CGRect, displayID: CGDirectDisplayID) {
        guard !loading.contains(url) else { return }
        loading.insert(url)
        queue.async { [weak self] in
            let sample = WallpaperSampler.makeSample(url: url, screenFrame: screenFrame)
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loading.remove(url)
                if let sample = sample {
                    self.samples[displayID] = sample
                    self.version += 1
                }
            }
        }
    }

    /// Decodes the wallpaper into a small luminance grid, cropped the way macOS "Fill Screen" does.
    private static func makeSample(url: URL, screenFrame: CGRect) -> Sample? {
        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        guard !isDirectory,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: 512
              ] as CFDictionary) else { return nil }

        let w = gridWidth
        let h = max(1, Int((CGFloat(w) * screenFrame.height / max(1, screenFrame.width)).rounded()))
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        // Aspect-fill: scale the image to cover the grid, centred.
        let iw = CGFloat(image.width), ih = CGFloat(image.height)
        let scale = max(CGFloat(w) / iw, CGFloat(h) / ih)
        let drawRect = CGRect(x: (CGFloat(w) - iw * scale) / 2, y: (CGFloat(h) - ih * scale) / 2, width: iw * scale, height: ih * scale)
        ctx.interpolationQuality = .medium
        ctx.draw(image, in: drawRect)
        guard let data = ctx.data else { return nil }
        let px = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
        var lum = [Double](repeating: 0, count: w * h)
        // CGContext memory is top-down (row 0 = top of the image).
        for y in 0..<h {
            for x in 0..<w {
                let o = (y * w + x) * 4
                let c = RGBAColor(r: Double(px[o]) / 255, g: Double(px[o + 1]) / 255, b: Double(px[o + 2]) / 255)
                lum[y * w + x] = c.relativeLuminance
            }
        }
        return Sample(url: url, screenFrame: screenFrame, width: w, height: h, luminance: lum)
    }

    /// Average relative luminance (0 = black, 1 = white) of the wallpaper under `rect`
    /// (global AppKit coordinates), or nil if not known yet.
    public func luminance(behind rect: CGRect) -> Double? {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        guard let sample = samples.values.first(where: { $0.screenFrame.contains(center) })
                ?? samples.values.max(by: { a, b in
                    let ia = a.screenFrame.intersection(rect), ib = b.screenFrame.intersection(rect)
                    return (ia.isNull ? 0 : ia.width * ia.height) < (ib.isNull ? 0 : ib.width * ib.height)
                }) else { return nil }
        return WallpaperSampler.average(sample.luminance, width: sample.width, height: sample.height,
                                        screenFrame: sample.screenFrame, rect: rect)
    }

    /// Pure helper (unit-tested): average of a top-down luminance grid over a global rect.
    static func average(_ lum: [Double], width: Int, height: Int, screenFrame: CGRect, rect: CGRect) -> Double? {
        let r = rect.intersection(screenFrame)
        guard !r.isNull, r.width > 0, r.height > 0, width > 0, height > 0 else { return nil }
        let x0 = Int(((r.minX - screenFrame.minX) / screenFrame.width * CGFloat(width)).rounded(.down))
        let x1 = Int(((r.maxX - screenFrame.minX) / screenFrame.width * CGFloat(width)).rounded(.up))
        // AppKit y grows upward; grid row 0 is the top of the screen.
        let y0 = Int(((screenFrame.maxY - r.maxY) / screenFrame.height * CGFloat(height)).rounded(.down))
        let y1 = Int(((screenFrame.maxY - r.minY) / screenFrame.height * CGFloat(height)).rounded(.up))
        var total = 0.0
        var count = 0
        for y in max(0, y0)..<min(height, max(y0 + 1, y1)) {
            for x in max(0, x0)..<min(width, max(x0 + 1, x1)) {
                total += lum[y * width + x]
                count += 1
            }
        }
        return count > 0 ? total / Double(count) : nil
    }

    // Test hook
    func injectSample(displayID: CGDirectDisplayID, screenFrame: CGRect, width: Int, height: Int, luminance: [Double]) {
        samples[displayID] = Sample(url: URL(fileURLWithPath: "/dev/null"), screenFrame: screenFrame, width: width, height: height, luminance: luminance)
        version += 1
    }
}
