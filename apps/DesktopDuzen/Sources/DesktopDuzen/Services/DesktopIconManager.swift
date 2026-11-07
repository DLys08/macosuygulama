import Foundation

public class DesktopIconManager {
    public static let shared = DesktopIconManager()
    
    public init() {}
    
    public func areDesktopIconsHidden() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "com.apple.finder", "CreateDesktop"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            return output == "0" || output.lowercased() == "false"
        }
        return false
    }
    
    public func setDesktopIconsHidden(_ hidden: Bool) {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["write", "com.apple.finder", "CreateDesktop", "-bool", hidden ? "false" : "true"]
        task.launch()
        task.waitUntilExit()
        
        // Restart Finder gracefully
        let killTask = Process()
        killTask.launchPath = "/usr/bin/killall"
        killTask.arguments = ["Finder"]
        killTask.launch()
        killTask.waitUntilExit()
    }
}
