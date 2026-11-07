import SwiftUI
import AppKit

public struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: SettingsTab = .general
    @State private var exportedJSON: String = ""
    @State private var isExportAlertPresented: Bool = false
    @State private var isImportPresented: Bool = false
    @State private var importJSONText: String = ""
    @State private var importErrorAlert: Bool = false
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case zones = "Zones"
        case autoSort = "Auto-Sort"
        case proLicense = "Pro & License"
        case about = "About"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .general: return "gearshape"
            case .zones: return "square.grid.2x2"
            case .autoSort: return "tray.full.fill"
            case .proLicense: return "crown.fill"
            case .about: return "info.circle"
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            HStack(spacing: 8) {
                ForEach(SettingsTab.allCases) { tab in
                    let isSelected = (selectedTab == tab)
                    Button(action: { selectedTab = tab }) {
                        Label(tab.rawValue, systemImage: tab.iconName)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            
            Divider()
            
            // Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    switch selectedTab {
                    case .general:
                        generalSettingsTab
                    case .zones:
                        zonesSettingsTab
                    case .autoSort:
                        autoSortSettingsTab
                    case .proLicense:
                        proLicenseSettingsTab
                    case .about:
                        aboutSettingsTab
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 660, height: 480)
    }
    
    // MARK: - General Tab
    
    @ViewBuilder
    private var generalSettingsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System & Window Behavior")
                .font(.system(size: 13, weight: .bold))
            
            Toggle("Launch DesktopDüzen at Login", isOn: $appState.settings.launchAtLogin)
            
            Toggle("Show Zones on All Spaces (Virtual Desktops)", isOn: $appState.settings.showZonesOnAllSpaces)
            
            Divider()
            
            Text("Alignment & Snapping")
                .font(.system(size: 13, weight: .bold))
            
            Toggle("Enable Alignment & Edge Snapping", isOn: $appState.settings.alignmentMode)
            
            Toggle("Snap to Grid", isOn: $appState.settings.snapToGrid)
                .disabled(!appState.settings.alignmentMode)
            
            HStack {
                Text("Grid Size:")
                    .frame(width: 120, alignment: .leading)
                Slider(value: $appState.settings.gridSize, in: 10...40, step: 5)
                Text("\(Int(appState.settings.gridSize)) px")
                    .frame(width: 50, alignment: .trailing)
            }
            .disabled(!appState.settings.alignmentMode || !appState.settings.snapToGrid)
            
            Toggle("Snap to Neighbor Zone Edges", isOn: $appState.settings.snapToNeighbors)
                .disabled(!appState.settings.alignmentMode)
            
            Divider()
            
            Text("Desktop Wallpaper Clutter")
                .font(.system(size: 13, weight: .bold))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hide Loose Desktop Icons")
                        .font(.system(size: 12, weight: .medium))
                    Text("Hides loose files sitting on wallpaper while keeping all your zones accessible.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.settings.hideLooseDesktopIcons },
                    set: { val in
                        DesktopIconManager.shared.setDesktopIconsHidden(val)
                        appState.settings.hideLooseDesktopIcons = val
                    }
                ))
            }
        }
    }
    
    // MARK: - Zones Tab
    
    @ViewBuilder
    private var zonesSettingsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Active Zones (\(appState.zones.count))")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button("Auto-Align All Zones") {
                    appState.autoAlignAllZones()
                }
                .buttonStyle(.bordered)
            }
            
            ForEach(appState.zones) { zone in
                HStack(spacing: 12) {
                    Image(systemName: zone.type.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(.cyan)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zone.title)
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(zone.type.rawValue) • \(zone.viewMode.rawValue) View • \(zone.isPinnedOnTop ? "Pinned on Top" : "Desktop Level")")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Edit Style") {
                        if let panel = NSApp.windows.first(where: { ($0 as? ZonePanel)?.zoneID == zone.id }) {
                            panel.makeKeyAndOrderFront(nil)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(role: .destructive, action: {
                        appState.deleteZone(id: zone.id, action: .moveFilesToDesktop)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
            }
            
            HStack(spacing: 10) {
                Button("+ New File Zone") {
                    _ = appState.createDefaultFileZone(title: "New Zone")
                }
                .buttonStyle(.borderedProminent)
                
                Button("+ New Folder Zone") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    if panel.runModal() == .OK, let url = panel.url {
                        _ = appState.createFolderZone(title: url.lastPathComponent, folderURL: url)
                    }
                }
                .buttonStyle(.bordered)
                
                Button("+ New App Zone") {
                    _ = appState.createAppZone(title: "App Launcher")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 6)
        }
    }
    
    // MARK: - Auto-Sort Tab
    
    @ViewBuilder
    private var autoSortSettingsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Smart Auto-Sort Rules")
                            .font(.system(size: 13, weight: .bold))
                        if !appState.isPro {
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                    Text("Automatically routes files placed on ~/Desktop into their corresponding zone folder.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Run Sort Now") {
                    let count = AutoSortService.shared.runAutoSort(
                        rules: appState.autoSortRules,
                        zones: appState.zones,
                        isPro: appState.isPro
                    )
                    let alert = NSAlert()
                    alert.messageText = "Auto-Sort Complete"
                    alert.informativeText = "Sorted \(count) files."
                    alert.runModal()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!appState.isPro)
            }
            
            Toggle("Continuously Monitor & Auto-Sort Desktop", isOn: Binding(
                get: { appState.settings.autoSortEnabled },
                set: { val in
                    if !appState.isPro && val {
                        WindowManager.shared.showPaywall()
                        return
                    }
                    appState.settings.autoSortEnabled = val
                    if val {
                        AutoSortService.shared.startMonitoring(rules: appState.autoSortRules, zones: appState.zones, isPro: appState.isPro)
                    } else {
                        AutoSortService.shared.stopMonitoring()
                    }
                }
            ))
            
            Divider()
            
            Text("Configured Rules")
                .font(.system(size: 12, weight: .semibold))
            
            ForEach($appState.autoSortRules) { $rule in
                HStack(spacing: 10) {
                    Toggle("", isOn: $rule.isEnabled)
                        .labelsHidden()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rule.name)
                            .font(.system(size: 12, weight: .medium))
                        Text("Target Zone: \(rule.targetZoneTitle) • Exts: \(rule.extensions.joined(separator: ", "))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
            }
        }
    }
    
    // MARK: - Pro & License Tab
    
    @ViewBuilder
    private var proLicenseSettingsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pro License Status")
                        .font(.system(size: 13, weight: .bold))
                    Text(appState.isPro ? "All Pro features unlocked (\(appState.license.activePlan?.rawValue ?? "Lifetime"))" : "Free Tier Active (Limited to 3 zones)")
                        .font(.system(size: 12))
                        .foregroundColor(appState.isPro ? .green : .secondary)
                }
                Spacer()
                Button(appState.isPro ? "View Paywall" : "Upgrade to Pro") {
                    WindowManager.shared.showPaywall()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            
            Toggle("Testing Switch: Toggle Pro Status", isOn: Binding(
                get: { appState.license.isPro },
                set: { val in
                    appState.license.isPro = val
                    appState.license.isMockProActive = val
                }
            ))
            
            Divider()
            
            Text("Backup & Configuration (JSON)")
                .font(.system(size: 13, weight: .bold))
            
            HStack(spacing: 12) {
                Button("Export Layout JSON") {
                    if let json = appState.exportConfigurationJSON() {
                        exportedJSON = json
                        isExportAlertPresented = true
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Import Layout JSON...") {
                    isImportPresented = true
                }
                .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: $isExportAlertPresented) {
            VStack(spacing: 12) {
                Text("Exported Zone Configuration")
                    .font(.headline)
                TextEditor(text: .constant(exportedJSON))
                    .font(.system(size: 11, design: .monospaced))
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                Button("Close") { isExportAlertPresented = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(width: 500, height: 350)
        }
        .sheet(isPresented: $isImportPresented) {
            VStack(spacing: 12) {
                Text("Import Zone Configuration")
                    .font(.headline)
                Text("Paste your exported JSON configuration below:")
                    .font(.caption)
                TextEditor(text: $importJSONText)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                HStack {
                    Button("Cancel") { isImportPresented = false }
                    Button("Import") {
                        if appState.importConfigurationJSON(importJSONText) {
                            isImportPresented = false
                        } else {
                            importErrorAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 500, height: 350)
            .alert("Invalid JSON format", isPresented: $importErrorAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    // MARK: - About Tab
    
    @ViewBuilder
    private var aboutSettingsTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 48))
                .foregroundColor(.cyan)
            
            Text("DesktopDüzen")
                .font(.system(size: 18, weight: .bold))
            
            Text("Version 1.0.0 (Build 371)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text("Full-featured macOS desktop workspace and zone organizer. Built with Swift, AppKit, and SwiftUI.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 420)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 30)
    }
}
