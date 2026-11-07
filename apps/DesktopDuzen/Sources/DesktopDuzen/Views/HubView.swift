import SwiftUI
import AppKit

public struct HubView: View {
    @EnvironmentObject var appState: AppState
    @State private var newZoneTitle: String = ""
    @State private var isCreatingZone: Bool = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("DesktopDüzen Hub")
                            .font(.system(size: 18, weight: .bold))
                        
                        Text(appState.isPro ? "★ PRO ACTIVE" : "FREE TIER")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(appState.isPro ? .green : .orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(appState.isPro ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    Text("Manage and customize your macOS desktop zones and widgets")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { WindowManager.shared.showSettings() }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
            }
            .padding(18)
            .background(Color.white.opacity(0.04))
            
            Divider()
            
            // Quick Action Buttons Grid
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Quick Actions")
                        .font(.system(size: 13, weight: .bold))
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        actionCard(title: "New File Zone", icon: "folder.badge.plus", color: .blue) {
                            promptCreateFileZone()
                        }
                        
                        actionCard(title: "Folder Zone", icon: "arrow.up.right.square", color: .purple) {
                            promptCreateFolderZone()
                        }
                        
                        actionCard(title: "New App Zone", icon: "square.grid.2x2.fill", color: .cyan) {
                            promptCreateAppZone()
                        }
                        
                        actionCard(title: "Add Clock", icon: "clock.fill", color: .orange) {
                            addClockWidget()
                        }
                        
                        actionCard(title: "Sticky Note", icon: "note.text", color: .yellow) {
                            addStickyNoteWidget()
                        }
                        
                        actionCard(title: "Auto-Align All", icon: "rectangle.3.group", color: .green) {
                            appState.autoAlignAllZones()
                        }
                        
                        actionCard(title: "Run Auto-Sort", icon: "bolt.fill", color: .indigo) {
                            runAutoSortNow()
                        }
                        
                        actionCard(title: "Search Zones", icon: "magnifyingglass", color: .pink) {
                            WindowManager.shared.toggleGlobalSearch()
                        }
                    }
                    
                    Divider().padding(.vertical, 4)
                    
                    // Active Zones List
                    HStack {
                        Text("Active Desktop Zones (\(appState.zones.count))")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Button("Align Grid") {
                            appState.autoAlignAllZones()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if appState.zones.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No zones active. Click '+ New File Zone' above to create one!")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(10)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(appState.zones) { zone in
                                HStack(spacing: 12) {
                                    Image(systemName: zone.type.iconName)
                                        .font(.system(size: 18))
                                        .foregroundColor(.cyan)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(zone.title)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text("\(zone.type.rawValue) • \(zone.viewMode.rawValue) View • \(zone.isPinnedOnTop ? "Pinned on Top" : "Desktop Level")")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if zone.type != .app {
                                        Button("Reveal Folder") {
                                            let url = URL(fileURLWithPath: zone.resolvedFolderPath)
                                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                    
                                    Button("Focus") {
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
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("DesktopDüzen is running. Click status icon in menu bar or right-click any zone to customize.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Close Hub") {
                    NSApp.keyWindow?.orderOut(nil)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.03))
        }
        .frame(width: 680, height: 540)
    }
    
    @ViewBuilder
    private func actionCard(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    
    private func promptCreateFileZone() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "New File Zone"
        alert.informativeText = "Enter name for the new File Zone:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        input.stringValue = "New Zone"
        alert.accessoryView = input
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = appState.createDefaultFileZone(title: name.isEmpty ? "New Zone" : name)
        }
    }
    
    private func promptCreateFolderZone() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.prompt = "Choose Folder"
        if panel.runModal() == .OK, let url = panel.url {
            _ = appState.createFolderZone(title: url.lastPathComponent, folderURL: url)
        }
    }
    
    private func promptCreateAppZone() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "New App Zone"
        alert.informativeText = "Enter name for App Zone:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        input.stringValue = "App Launcher"
        alert.accessoryView = input
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = appState.createAppZone(title: name.isEmpty ? "App Launcher" : name)
        }
    }
    
    private func addClockWidget() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let widget = DesktopWidget(
            type: .clock,
            title: "Desktop Clock",
            frame: CGRect(x: screen.minX + 60, y: screen.minY + 120, width: 220, height: 120)
        )
        appState.widgets.append(widget)
    }
    
    private func addStickyNoteWidget() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let widget = DesktopWidget(
            type: .quickNote,
            title: "Quick Note",
            frame: CGRect(x: screen.minX + 300, y: screen.minY + 120, width: 220, height: 160)
        )
        appState.widgets.append(widget)
    }
    
    private func runAutoSortNow() {
        let count = AutoSortService.shared.runAutoSort(
            rules: appState.autoSortRules,
            zones: appState.zones,
            isPro: appState.isPro
        )
        let alert = NSAlert()
        alert.messageText = "Auto-Sort Complete"
        alert.informativeText = "Organized \(count) file(s) on Desktop."
        alert.runModal()
    }
}
