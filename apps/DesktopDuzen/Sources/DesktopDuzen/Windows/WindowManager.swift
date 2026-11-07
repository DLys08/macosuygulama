import Foundation
import AppKit
import SwiftUI
import Combine

public class WindowManager: ObservableObject {
    public static let shared = WindowManager()
    
    private var zonePanels: [UUID: ZonePanel] = [:]
    private var widgetPanels: [UUID: NSPanel] = [:]
    private var stickerPanels: [UUID: NSPanel] = [:]
    
    private var settingsWindow: NSWindow?
    private var paywallWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var searchWindow: NSPanel?
    private var hubWindow: NSWindow?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupScreenChangeObserver()
    }
    
    public func start() {
        observeAppState()
        syncAllZones()
        syncAllWidgets()
        syncAllStickers()
    }
    
    private func observeAppState() {
        AppState.shared.$zones
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncAllZones()
            }
            .store(in: &cancellables)
            
        AppState.shared.$widgets
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncAllWidgets()
            }
            .store(in: &cancellables)
            
        AppState.shared.$stickers
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncAllStickers()
            }
            .store(in: &cancellables)
            
        AppState.shared.$areAllZonesHidden
            .receive(on: RunLoop.main)
            .sink { [weak self] isHidden in
                self?.setAllZonesHidden(isHidden)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Screen Handling
    
    private func setupScreenChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenParametersChanged()
        }
    }
    
    private func handleScreenParametersChanged() {
        guard let mainScreen = NSScreen.main else { return }
        let visible = mainScreen.visibleFrame
        
        for (id, panel) in zonePanels {
            let frame = panel.frame
            // Check if frame is off-screen
            var onAnyScreen = false
            for screen in NSScreen.screens {
                if screen.frame.intersects(frame) {
                    onAnyScreen = true
                    break
                }
            }
            
            if !onAnyScreen {
                var safeRect = frame
                safeRect.origin.x = visible.minX + 50
                safeRect.origin.y = visible.minY + 50
                panel.setFrame(safeRect, display: true, animate: true)
                
                if let idx = AppState.shared.zones.firstIndex(where: { $0.id == id }) {
                    AppState.shared.zones[idx].frame = safeRect
                }
            }
        }
    }
    
    // MARK: - Zones Sync
    
    public func syncAllZones() {
        let currentZones = AppState.shared.zones
        let currentIDs = Set(currentZones.map { $0.id })
        
        // Remove dead panels
        for (id, panel) in zonePanels where !currentIDs.contains(id) {
            panel.orderOut(nil)
            zonePanels.removeValue(forKey: id)
        }
        
        // Add or update panels
        for zone in currentZones {
            if let existing = zonePanels[zone.id] {
                // Update properties
                existing.updateWindowLevel(isPinnedOnTop: zone.isPinnedOnTop)
            } else {
                createZonePanel(for: zone)
            }
        }
    }
    
    private func createZonePanel(for zone: ZoneModel) {
        let panel = ZonePanel(zone: zone, contentRect: zone.frame)
        
        let contentView = ZoneContentView(zoneID: zone.id)
            .environmentObject(AppState.shared)
        
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        zonePanels[zone.id] = panel
        
        if !AppState.shared.areAllZonesHidden {
            panel.orderFront(nil)
        }
    }
    
    public func getOtherZoneFrames(excluding id: UUID) -> [NSRect] {
        return zonePanels.filter { $0.key != id }.map { $0.value.frame }
    }
    
    public func updatePanelFrame(id: UUID, newFrame: NSRect) {
        if let panel = zonePanels[id] {
            panel.setFrame(newFrame, display: true)
        }
    }
    
    public func setAllZonesHidden(_ hidden: Bool) {
        for (_, panel) in zonePanels {
            if hidden {
                panel.orderOut(nil)
            } else {
                panel.orderFront(nil)
            }
        }
        for (_, panel) in widgetPanels {
            if hidden { panel.orderOut(nil) } else { panel.orderFront(nil) }
        }
        for (_, panel) in stickerPanels {
            if hidden { panel.orderOut(nil) } else { panel.orderFront(nil) }
        }
    }
    
    // MARK: - Widgets Sync
    
    public func syncAllWidgets() {
        let widgets = AppState.shared.widgets
        let ids = Set(widgets.map { $0.id })
        
        for (id, panel) in widgetPanels where !ids.contains(id) {
            panel.orderOut(nil)
            widgetPanels.removeValue(forKey: id)
        }
        
        for widget in widgets {
            if widgetPanels[widget.id] == nil {
                createWidgetPanel(for: widget)
            }
        }
    }
    
    private func createWidgetPanel(for widget: DesktopWidget) {
        let panel = NSPanel(
            contentRect: widget.frame,
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .normal
        panel.orderBack(nil)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        
        let view = WidgetContainerView(widgetID: widget.id)
            .environmentObject(AppState.shared)
        panel.contentView = NSHostingView(rootView: view)
        
        widgetPanels[widget.id] = panel
        if !AppState.shared.areAllZonesHidden {
            panel.orderFront(nil)
        }
    }
    
    // MARK: - Stickers Sync
    
    public func syncAllStickers() {
        let stickers = AppState.shared.stickers
        let ids = Set(stickers.map { $0.id })
        
        for (id, panel) in stickerPanels where !ids.contains(id) {
            panel.orderOut(nil)
            stickerPanels.removeValue(forKey: id)
        }
        
        for sticker in stickers {
            if stickerPanels[sticker.id] == nil {
                createStickerPanel(for: sticker)
            }
        }
    }
    
    private func createStickerPanel(for sticker: DesktopSticker) {
        let panel = NSPanel(
            contentRect: sticker.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .normal
        panel.orderBack(nil)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        
        let view = StickerView(stickerID: sticker.id)
            .environmentObject(AppState.shared)
        panel.contentView = NSHostingView(rootView: view)
        
        stickerPanels[sticker.id] = panel
        if !AppState.shared.areAllZonesHidden {
            panel.orderFront(nil)
        }
    }
    
    // MARK: - Modals (Hub, Settings, Paywall, Search, Onboarding)
    
    public func showHub() {
        if let window = hubWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 680, height: 540),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DesktopDüzen Hub"
        window.center()
        window.contentView = NSHostingView(rootView: HubView().environmentObject(AppState.shared))
        window.isReleasedWhenClosed = false
        
        self.hubWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 720, height: 540),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DesktopDüzen Preferences"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView().environmentObject(AppState.shared))
        window.isReleasedWhenClosed = false
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func showPaywall() {
        if let window = paywallWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 680, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Upgrade to DesktopDüzen Pro"
        window.center()
        window.contentView = NSHostingView(rootView: PaywallView().environmentObject(AppState.shared))
        window.isReleasedWhenClosed = false
        
        self.paywallWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func showOnboarding() {
        if let window = onboardingWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 620, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to DesktopDüzen"
        window.center()
        window.contentView = NSHostingView(rootView: OnboardingView().environmentObject(AppState.shared))
        window.isReleasedWhenClosed = false
        
        self.onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func toggleGlobalSearch() {
        if let search = searchWindow, search.isVisible {
            search.orderOut(nil)
            return
        }
        
        if searchWindow == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 420),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.level = .floating
            panel.center()
            panel.contentView = NSHostingView(rootView: GlobalSearchView().environmentObject(AppState.shared))
            self.searchWindow = panel
        }
        
        searchWindow?.center()
        searchWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
