import Cocoa
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce Single Instance: Kill or activate existing instance
        let bundleID = Bundle.main.bundleIdentifier ?? "com.desktopduzen.app"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if runningApps.count > 1 {
            for app in runningApps where app != NSRunningApplication.current {
                app.activate(options: [.activateIgnoringOtherApps])
            }
            NSApp.terminate(nil)
            return
        }
        
        // Configure Activation Policy: Regular allows Dock icon and menu bar access
        NSApp.setActivationPolicy(.regular)
        
        // Initialize Status Menu Bar Item
        MenuBarManager.shared.setupMenuBar()
        
        // Start Window Manager (syncs all zones, widgets, stickers onto desktop canvas)
        WindowManager.shared.start()
        
        // Show Welcome / Onboarding on first run, or show Hub window
        if !AppState.shared.settings.hasCompletedOnboarding {
            WindowManager.shared.showOnboarding()
        } else {
            WindowManager.shared.showHub()
        }
        
        // Start Auto-Sort if enabled
        if AppState.shared.settings.autoSortEnabled && AppState.shared.isPro {
            AutoSortService.shared.startMonitoring(
                rules: AppState.shared.autoSortRules,
                zones: AppState.shared.zones,
                isPro: AppState.shared.isPro
            )
        }
        
        // Global Hotkey for Cmd+Shift+Space (Global Search)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 49 {
                WindowManager.shared.toggleGlobalSearch()
                return nil
            }
            return event
        }
    }
    
    // When user clicks Dock icon or relaunches from Applications/Finder, show Hub / Settings
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        WindowManager.shared.showHub()
        return true
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
