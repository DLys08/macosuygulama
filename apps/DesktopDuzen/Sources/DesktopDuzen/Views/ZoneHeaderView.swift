import SwiftUI
import AppKit

public struct ZoneHeaderView: View {
    @ObservedObject var appState: AppState
    let zone: ZoneModel
    @Binding var isEditingTitle: Bool
    @State private var editedTitle: String = ""
    @State private var isStylePickerPresented: Bool = false
    @State private var isDeleteConfirmationPresented: Bool = false
    @State private var deleteActionChoice: ZoneDeleteAction = .moveFilesToDesktop
    
    public init(appState: AppState, zone: ZoneModel, isEditingTitle: Binding<Bool>) {
        self.appState = appState
        self.zone = zone
        self._isEditingTitle = isEditingTitle
    }
    
    private var theme: ZoneTheme {
        ThemePresets.theme(for: zone.themeID)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Zone Icon
                Image(systemName: zone.type.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: theme.accentColorHex))
                
                // Zone Title (Inline Rename)
                if isEditingTitle {
                    TextField("Zone Name", text: $editedTitle, onCommit: {
                        commitRename()
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(4)
                    .onAppear {
                        editedTitle = zone.title
                    }
                } else {
                    Text(zone.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: theme.titleColorHex))
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            editedTitle = zone.title
                            isEditingTitle = true
                        }
                        .help("Double-click to rename")
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 4) {
                    // Pin to top toggle
                    Button(action: togglePinOnTop) {
                        Image(systemName: zone.isPinnedOnTop ? "pin.fill" : "pin")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(zone.isPinnedOnTop ? Color.yellow : Color.white.opacity(0.7))
                            .padding(4)
                            .background(Color.white.opacity(zone.isPinnedOnTop ? 0.2 : 0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(zone.isPinnedOnTop ? "Unpin (Return to Desktop level)" : "Pin on top of other windows (Pro)")
                    
                    // Style Picker Popover
                    Button(action: { isStylePickerPresented.toggle() }) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.7))
                            .padding(4)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .popover(isPresented: $isStylePickerPresented) {
                        ZoneStylePickerView(zoneID: zone.id)
                            .environmentObject(appState)
                    }
                    .help("Customize Theme & Styling")
                    
                    // Collapse / Expand toggle
                    Button(action: toggleCollapse) {
                        Image(systemName: zone.isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                            .padding(4)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(zone.isCollapsed ? "Expand Zone" : "Collapse Zone to Title Bar")
                    
                    // More options menu
                    Menu {
                        Section("View Mode") {
                            Button(action: { setViewMode(.icon) }) {
                                Label("Icon View", systemImage: "square.grid.3x3")
                            }
                            Button(action: { setViewMode(.list) }) {
                                Label("List View", systemImage: "list.bullet")
                            }
                        }
                        
                        Section("Sort By") {
                            ForEach(ZoneSortMode.allCases, id: \.self) { mode in
                                Button(action: { setSortMode(mode) }) {
                                    HStack {
                                        Text(mode.rawValue)
                                        if zone.sortMode == mode {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        if zone.type != .app {
                            Section("Tabs (Pro)") {
                                Button(action: addNewTab) {
                                    Label("Add New Tab...", systemImage: "plus.rectangle.on.rectangle")
                                }
                            }
                            
                            Section("Folder Actions") {
                                Button(action: revealInFinder) {
                                    Label("Reveal Zone in Finder", systemImage: "arrow.up.forward.app")
                                }
                            }
                        }
                        
                        Section {
                            Button(action: {
                                editedTitle = zone.title
                                isEditingTitle = true
                            }) {
                                Label("Rename Zone...", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                isDeleteConfirmationPresented = true
                            }) {
                                Label("Delete Zone...", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                            .padding(4)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .frame(width: 20)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // Tab Strip (if zone has tabs)
            if !zone.tabs.isEmpty && !zone.isCollapsed {
                HStack(spacing: 4) {
                    ForEach(zone.tabs) { tab in
                        let isSelected = (zone.activeTabID == tab.id)
                        Button(action: { selectTab(tab.id) }) {
                            Text(tab.title)
                                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button("Rename Tab...") { renameTab(tab) }
                            Button(role: .destructive, action: { deleteTab(tab) }) {
                                Text("Delete Tab")
                            }
                        }
                    }
                    
                    Button(action: addNewTab) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(4)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Add Tab")
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
        }
        .confirmationDialog("Delete Zone '\(zone.title)'?", isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
            Button("Move files back to Desktop and delete zone", role: .destructive) {
                appState.deleteZone(id: zone.id, action: .moveFilesToDesktop)
            }
            Button("Move zone folder to Trash", role: .destructive) {
                appState.deleteZone(id: zone.id, action: .moveToTrash)
            }
            Button("Keep folder on disk (remove zone only)") {
                appState.deleteZone(id: zone.id, action: .unbindOnly)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What would you like to do with the files inside this zone?")
        }
    }
    
    // MARK: - Handlers
    
    private func commitRename() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            appState.renameZone(id: zone.id, newTitle: trimmed)
        }
        isEditingTitle = false
    }
    
    private func togglePinOnTop() {
        if !appState.canPinOnTop() && !zone.isPinnedOnTop {
            WindowManager.shared.showPaywall()
            return
        }
        var updated = zone
        updated.isPinnedOnTop.toggle()
        appState.updateZone(updated)
        WindowManager.shared.syncAllZones()
    }
    
    private func toggleCollapse() {
        var updated = zone
        updated.isCollapsed.toggle()
        
        // Calculate new window frame
        var newFrame = zone.frame
        if updated.isCollapsed {
            updated.expandedHeight = zone.frame.height
            newFrame.origin.y += (zone.frame.height - zone.collapsedHeight)
            newFrame.size.height = zone.collapsedHeight
        } else {
            let expHeight = zone.expandedHeight > 60 ? zone.expandedHeight : 260.0
            newFrame.origin.y -= (expHeight - zone.frame.height)
            newFrame.size.height = expHeight
        }
        
        updated.frame = newFrame
        appState.updateZone(updated)
        WindowManager.shared.updatePanelFrame(id: zone.id, newFrame: newFrame)
    }
    
    private func setViewMode(_ mode: ZoneViewMode) {
        var updated = zone
        updated.viewMode = mode
        appState.updateZone(updated)
    }
    
    private func setSortMode(_ mode: ZoneSortMode) {
        var updated = zone
        updated.sortMode = mode
        appState.updateZone(updated)
    }
    
    private func revealInFinder() {
        let url = URL(fileURLWithPath: zone.resolvedFolderPath)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
    
    private func addNewTab() {
        if !appState.canUseTabs() {
            WindowManager.shared.showPaywall()
            return
        }
        let alert = NSAlert()
        alert.messageText = "New Zone Tab"
        alert.informativeText = "Enter a title for this tab:"
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = "Tab \(zone.tabs.count + 1)"
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let tabName = name.isEmpty ? "New Tab" : name
            
            // Create subfolder on disk
            let subfolderURL = URL(fileURLWithPath: zone.backingFolderPath).appendingPathComponent(tabName, isDirectory: true)
            try? FileManager.default.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
            
            var updated = zone
            let newTab = ZoneTab(title: tabName, subfolderName: tabName, order: zone.tabs.count)
            updated.tabs.append(newTab)
            updated.activeTabID = newTab.id
            appState.updateZone(updated)
        }
    }
    
    private func selectTab(_ id: UUID) {
        var updated = zone
        updated.activeTabID = id
        appState.updateZone(updated)
    }
    
    private func renameTab(_ tab: ZoneTab) {
        let alert = NSAlert()
        alert.messageText = "Rename Tab"
        alert.informativeText = "Enter new name for tab:"
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = tab.title
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let newName = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newName.isEmpty {
                var updated = zone
                if let idx = updated.tabs.firstIndex(where: { $0.id == tab.id }) {
                    updated.tabs[idx].title = newName
                    appState.updateZone(updated)
                }
            }
        }
    }
    
    private func deleteTab(_ tab: ZoneTab) {
        var updated = zone
        updated.tabs.removeAll(where: { $0.id == tab.id })
        if updated.activeTabID == tab.id {
            updated.activeTabID = updated.tabs.first?.id
        }
        appState.updateZone(updated)
    }
}
