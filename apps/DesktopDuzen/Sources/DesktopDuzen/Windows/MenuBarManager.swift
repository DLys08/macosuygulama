import Foundation
import AppKit

public class MenuBarManager: NSObject {
    public static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    
    public func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use custom icon or SF Symbol
            let image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "DesktopDüzen")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "DesktopDüzen - File Zones"
        }
        
        rebuildMenu()
    }
    
    public func rebuildMenu() {
        let menu = NSMenu()
        
        // Header info
        let titleItem = NSMenuItem(title: "DesktopDüzen", action: nil, keyEquivalent: "")
        titleItem.attributedTitle = NSAttributedString(
            string: "DesktopDüzen",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        menu.addItem(titleItem)
        
        let proStatus = AppState.shared.isPro ? "★ Pro Active" : "Free Tier"
        let statusSubItem = NSMenuItem(title: "  \(proStatus)", action: #selector(openPaywall), keyEquivalent: "")
        statusSubItem.target = self
        menu.addItem(statusSubItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let hubItem = NSMenuItem(title: "Open DesktopDüzen Hub...", action: #selector(openHub), keyEquivalent: "o")
        hubItem.target = self
        hubItem.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: nil)
        menu.addItem(hubItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Zone creation actions
        let newFileZoneItem = NSMenuItem(title: "New File Zone...", action: #selector(newFileZone), keyEquivalent: "n")
        newFileZoneItem.target = self
        newFileZoneItem.image = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil)
        menu.addItem(newFileZoneItem)
        
        let newFolderZoneItem = NSMenuItem(title: "New Folder Zone (Quick Access)...", action: #selector(newFolderZone), keyEquivalent: "f")
        newFolderZoneItem.target = self
        newFolderZoneItem.image = NSImage(systemSymbolName: "arrow.up.right.square", accessibilityDescription: nil)
        menu.addItem(newFolderZoneItem)
        
        let newAppZoneItem = NSMenuItem(title: "New App Zone...", action: #selector(newAppZone), keyEquivalent: "a")
        newAppZoneItem.target = self
        newAppZoneItem.image = NSImage(systemSymbolName: "square.grid.2x2.fill", accessibilityDescription: nil)
        menu.addItem(newAppZoneItem)
        
        // Widgets & Stickers submenu
        let widgetsMenu = NSMenu()
        for widgetType in WidgetType.allCases {
            let item = NSMenuItem(title: "Add \(widgetType.rawValue)", action: #selector(addWidget(_:)), keyEquivalent: "")
            item.representedObject = widgetType
            item.target = self
            item.image = NSImage(systemSymbolName: widgetType.iconName, accessibilityDescription: nil)
            widgetsMenu.addItem(item)
        }
        widgetsMenu.addItem(NSMenuItem.separator())
        let addStickerItem = NSMenuItem(title: "Add Desktop Sticker...", action: #selector(addSticker), keyEquivalent: "")
        addStickerItem.target = self
        addStickerItem.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
        widgetsMenu.addItem(addStickerItem)
        
        let widgetsParentItem = NSMenuItem(title: "Widgets & Stickers", action: nil, keyEquivalent: "")
        widgetsParentItem.submenu = widgetsMenu
        widgetsParentItem.image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: nil)
        menu.addItem(widgetsParentItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Layout and View actions
        let alignItem = NSMenuItem(title: "Auto-Align All Zones", action: #selector(autoAlignAll), keyEquivalent: "l")
        alignItem.target = self
        alignItem.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: nil)
        menu.addItem(alignItem)
        
        let snapState = AppState.shared.settings.alignmentMode ? "Disable Grid Snapping" : "Enable Grid Snapping"
        let snapItem = NSMenuItem(title: snapState, action: #selector(toggleGridSnapping), keyEquivalent: "")
        snapItem.target = self
        snapItem.state = AppState.shared.settings.alignmentMode ? .on : .off
        menu.addItem(snapItem)
        
        let hideZonesTitle = AppState.shared.areAllZonesHidden ? "Show All Zones" : "Hide All Zones"
        let hideZonesItem = NSMenuItem(title: hideZonesTitle, action: #selector(toggleHideAllZones), keyEquivalent: "h")
        hideZonesItem.target = self
        menu.addItem(hideZonesItem)
        
        let hideDesktopTitle = AppState.shared.settings.hideLooseDesktopIcons ? "Show Loose Desktop Icons" : "Hide Loose Desktop Icons"
        let hideDesktopItem = NSMenuItem(title: hideDesktopTitle, action: #selector(toggleDesktopIcons), keyEquivalent: "")
        hideDesktopItem.target = self
        hideDesktopItem.state = AppState.shared.settings.hideLooseDesktopIcons ? .on : .off
        menu.addItem(hideDesktopItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Smart Auto Sort
        let autoSortMenu = NSMenu()
        let runSortNow = NSMenuItem(title: "Run Auto-Sort Now", action: #selector(runAutoSortNow), keyEquivalent: "s")
        runSortNow.target = self
        runSortNow.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
        autoSortMenu.addItem(runSortNow)
        
        let autoSortToggle = NSMenuItem(title: "Automatic Sorting on Desktop", action: #selector(toggleAutoSort), keyEquivalent: "")
        autoSortToggle.target = self
        autoSortToggle.state = AppState.shared.settings.autoSortEnabled ? .on : .off
        autoSortMenu.addItem(autoSortToggle)
        
        let autoSortParent = NSMenuItem(title: "Smart Auto-Sort Rules", action: nil, keyEquivalent: "")
        autoSortParent.submenu = autoSortMenu
        autoSortParent.image = NSImage(systemSymbolName: "tray.full.fill", accessibilityDescription: nil)
        menu.addItem(autoSortParent)
        
        // Search
        let searchItem = NSMenuItem(title: "Search Across All Zones...", action: #selector(openSearch), keyEquivalent: " ")
        searchItem.keyEquivalentModifierMask = [.command, .shift]
        searchItem.target = self
        searchItem.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        menu.addItem(searchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings / Preferences
        let settingsItem = NSMenuItem(title: "Preferences...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)
        
        let paywallItem = NSMenuItem(title: AppState.shared.isPro ? "Pro License Details..." : "Upgrade to Pro...", action: #selector(openPaywall), keyEquivalent: "")
        paywallItem.target = self
        paywallItem.image = NSImage(systemSymbolName: "crown.fill", accessibilityDescription: nil)
        menu.addItem(paywallItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit DesktopDüzen", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    // MARK: - Actions
    
    @objc private func openHub() {
        NSApp.activate(ignoringOtherApps: true)
        WindowManager.shared.showHub()
    }
    
    @objc private func newFileZone() {
        NSApp.activate(ignoringOtherApps: true)
        if !AppState.shared.canAddZone() {
            WindowManager.shared.showPaywall()
            return
        }
        let alert = NSAlert()
        alert.messageText = "Create New File Zone"
        alert.informativeText = "Enter a name for the new File Zone:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        input.stringValue = "New Zone"
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = AppState.shared.createDefaultFileZone(title: name.isEmpty ? "New Zone" : name)
        }
    }
    
    @objc private func newFolderZone() {
        NSApp.activate(ignoringOtherApps: true)
        if !AppState.shared.canAddZone() {
            WindowManager.shared.showPaywall()
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder for Zone"
        panel.message = "Choose an existing folder to mirror onto your desktop:"
        
        if panel.runModal() == .OK, let folderURL = panel.url {
            let title = folderURL.lastPathComponent
            _ = AppState.shared.createFolderZone(title: title, folderURL: folderURL)
        }
    }
    
    @objc private func newAppZone() {
        NSApp.activate(ignoringOtherApps: true)
        if !AppState.shared.canAddZone() {
            WindowManager.shared.showPaywall()
            return
        }
        let alert = NSAlert()
        alert.messageText = "Create New App Zone"
        alert.informativeText = "Enter a name for the App Launcher zone:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        input.stringValue = "App Launcher"
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = AppState.shared.createAppZone(title: name.isEmpty ? "App Launcher" : name)
        }
    }
    
    @objc private func addWidget(_ sender: NSMenuItem) {
        guard let widgetType = sender.representedObject as? WidgetType else { return }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let widget = DesktopWidget(
            type: widgetType,
            title: widgetType.rawValue,
            frame: CGRect(x: screen.minX + 80, y: screen.minY + 120, width: 220, height: 160)
        )
        AppState.shared.widgets.append(widget)
    }
    
    @objc private func addSticker() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let sampleEmojis = ["🚀", "☕️", "⭐️", "🔥", "📌", "🎉", "💡", "🪴", "🐱", "🎯"]
        let randomEmoji = sampleEmojis.randomElement() ?? "⭐️"
        let sticker = DesktopSticker(
            content: randomEmoji,
            frame: CGRect(x: screen.midX, y: screen.midY, width: 72, height: 72)
        )
        AppState.shared.stickers.append(sticker)
    }
    
    @objc private func autoAlignAll() {
        AppState.shared.autoAlignAllZones()
    }
    
    @objc private func toggleGridSnapping() {
        AppState.shared.settings.alignmentMode.toggle()
        rebuildMenu()
    }
    
    @objc private func toggleHideAllZones() {
        AppState.shared.areAllZonesHidden.toggle()
        rebuildMenu()
    }
    
    @objc private func toggleDesktopIcons() {
        let current = AppState.shared.settings.hideLooseDesktopIcons
        let target = !current
        
        if target {
            let alert = NSAlert()
            alert.messageText = "Hide Loose Desktop Icons?"
            alert.informativeText = "This will hide files lying loose directly on the Desktop wallpaper while keeping your zones visible. Finder will restart briefly."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Hide Icons")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() != .alertFirstButtonReturn {
                return
            }
        }
        
        DesktopIconManager.shared.setDesktopIconsHidden(target)
        AppState.shared.settings.hideLooseDesktopIcons = target
        rebuildMenu()
    }
    
    @objc private func runAutoSortNow() {
        let count = AutoSortService.shared.runAutoSort(
            rules: AppState.shared.autoSortRules,
            zones: AppState.shared.zones,
            isPro: AppState.shared.isPro
        )
        let alert = NSAlert()
        alert.messageText = "Auto-Sort Complete"
        alert.informativeText = "Organized \(count) file(s) into matching zones."
        alert.runModal()
    }
    
    @objc private func toggleAutoSort() {
        if !AppState.shared.isPro {
            WindowManager.shared.showPaywall()
            return
        }
        AppState.shared.settings.autoSortEnabled.toggle()
        if AppState.shared.settings.autoSortEnabled {
            AutoSortService.shared.startMonitoring(
                rules: AppState.shared.autoSortRules,
                zones: AppState.shared.zones,
                isPro: AppState.shared.isPro
            )
        } else {
            AutoSortService.shared.stopMonitoring()
        }
        rebuildMenu()
    }
    
    @objc private func openSearch() {
        NSApp.activate(ignoringOtherApps: true)
        WindowManager.shared.toggleGlobalSearch()
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        WindowManager.shared.showSettings()
    }
    
    @objc private func openPaywall() {
        NSApp.activate(ignoringOtherApps: true)
        WindowManager.shared.showPaywall()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
