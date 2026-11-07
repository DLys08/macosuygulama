import Foundation
import ServiceManagement

/// Registers the app as a login item. Prefers SMAppService (macOS 13+); if the system refuses
/// (e.g. ad-hoc signed builds), falls back to a per-user LaunchAgent that runs `open -a`.
public final class LaunchAtLoginService {
    public static let shared = LaunchAtLoginService()

    private let agentLabel = "com.desktopduzen.app.launcher"

    private var agentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(agentLabel).plist")
    }

    public enum Method: String { case loginItem = "Login Item", launchAgent = "Launch Agent", none = "Off" }

    public var currentMethod: Method {
        if SMAppService.mainApp.status == .enabled { return .loginItem }
        if FileManager.default.fileExists(atPath: agentURL.path) { return .launchAgent }
        return .none
    }

    public var isEnabled: Bool { currentMethod != .none }

    /// Returns nil on success or a user-facing error message.
    @discardableResult
    public func setEnabled(_ enabled: Bool) -> String? {
        if enabled {
            do {
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .enabled {
                    removeAgent()
                    return nil
                }
            } catch {
                NSLog("DesktopDuzen: SMAppService register failed: \(error.localizedDescription); using LaunchAgent")
            }
            return installAgent()
        } else {
            if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
                try? SMAppService.mainApp.unregister()
            }
            removeAgent()
            return isEnabled ? "Could not turn off launch at login. Remove DesktopDüzen in System Settings > General > Login Items." : nil
        }
    }

    private func installAgent() -> String? {
        let appPath = Bundle.main.bundlePath
        guard appPath.hasSuffix(".app") else { return "Launch at login needs the app to run from an .app bundle." }
        let plist: [String: Any] = [
            "Label": agentLabel,
            "ProgramArguments": ["/usr/bin/open", "-g", "-a", appPath],
            "RunAtLoad": true,
            "ProcessType": "Interactive"
        ]
        do {
            try FileManager.default.createDirectory(at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: agentURL, options: .atomic)
            return nil
        } catch {
            return "Could not enable launch at login: \(error.localizedDescription)"
        }
    }

    private func removeAgent() {
        if FileManager.default.fileExists(atPath: agentURL.path) {
            try? FileManager.default.removeItem(at: agentURL)
        }
    }
}
