import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct ZoneContentView: View {
    @EnvironmentObject var appState: AppState
    let zoneID: UUID
    
    @State private var files: [FileItem] = []
    @State private var selectedFilePaths: Set<String> = []
    @State private var isEditingTitle: Bool = false
    @State private var isDropTargeted: Bool = false
    @State private var errorMessageBanner: String? = nil
    
    @State private var folderMonitor: FolderMonitor?
    
    private var zone: ZoneModel? {
        appState.zones.first(where: { $0.id == zoneID })
    }
    
    public var body: some View {
        if let currentZone = zone {
            let theme = ThemePresets.theme(for: currentZone.themeID)
            
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Title Bar / Header (Drag Area)
                    ZoneHeaderView(appState: appState, zone: currentZone, isEditingTitle: $isEditingTitle)
                        .background(Color.white.opacity(0.06))
                        .gesture(
                            DragGesture(minimumDistance: 3)
                                .onChanged { value in
                                    handleWindowDrag(translation: value.translation)
                                }
                        )
                    
                    // Error / Toast Banner
                    if let error = errorMessageBanner {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.yellow)
                            Text(error)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { errorMessageBanner = nil }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.75))
                    }
                    
                    // Body (when not collapsed)
                    if !currentZone.isCollapsed {
                        ZStack {
                            if currentZone.type == .app {
                                if currentZone.apps.isEmpty {
                                    emptyDropInvitation(text: "Drop applications (.app) here\nor click + to add shortcuts")
                                } else {
                                    AppZoneView(appState: appState, zone: currentZone)
                                }
                            } else {
                                if files.isEmpty {
                                    emptyDropInvitation(text: "Drag desktop files here to organize")
                                } else {
                                    if currentZone.viewMode == .icon {
                                        ZoneIconGridView(
                                            appState: appState,
                                            zone: currentZone,
                                            files: sortedFiles(files, mode: currentZone.sortMode),
                                            selectedFilePaths: $selectedFilePaths,
                                            onFileDoubleClicked: openFile,
                                            onFileRenamed: renameFile,
                                            onFileDeleted: deleteFile
                                        )
                                    } else {
                                        ZoneListView(
                                            appState: appState,
                                            zone: currentZone,
                                            files: sortedFiles(files, mode: currentZone.sortMode),
                                            selectedFilePaths: $selectedFilePaths,
                                            onFileDoubleClicked: openFile,
                                            onFileRenamed: renameFile,
                                            onFileDeleted: deleteFile
                                        )
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                // Resize Handle in bottom right corner
                if !currentZone.isCollapsed {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(6)
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    handleWindowResize(translation: value.translation)
                                }
                        )
                }
            }
            .background(
                ZStack {
                    // Material Blur
                    VisualEffectBlur(material: visualEffectMaterial(theme.materialStyle))
                    
                    // Background Color Tint & Opacity
                    Color(hex: theme.backgroundHex)
                        .opacity(theme.backgroundOpacity)
                }
            )
            .cornerRadius(CGFloat(theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius))
                    .stroke(
                        isDropTargeted ? Color(hex: theme.accentColorHex) : Color(hex: theme.borderHex),
                        lineWidth: isDropTargeted ? 2.5 : CGFloat(theme.borderWidth)
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
            .onAppear {
                setupFolderMonitor(for: currentZone)
                reloadFiles(for: currentZone)
            }
            .onChange(of: currentZone.backingFolderPath) { _ in
                setupFolderMonitor(for: currentZone)
                reloadFiles(for: currentZone)
            }
            .onChange(of: currentZone.activeTabID) { _ in
                setupFolderMonitor(for: currentZone)
                reloadFiles(for: currentZone)
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers: providers, zone: currentZone)
            }
            // Spacebar QuickLook key listener
            .background(KeyEventHandlerView { event in
                if event.keyCode == 49 { // Spacebar
                    let selectedURLs = files.filter { selectedFilePaths.contains($0.path) }.map { $0.url }
                    if !selectedURLs.isEmpty {
                        QuickLookManager.shared.togglePreview(urls: selectedURLs)
                        return true
                    }
                }
                return false
            })
        }
    }
    
    @ViewBuilder
    private func emptyDropInvitation(text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(.white.opacity(0.35))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - File Monitoring & Loading
    
    private func setupFolderMonitor(for zone: ZoneModel) {
        folderMonitor?.stop()
        folderMonitor = nil
        
        guard zone.type != .app else { return }
        let path = zone.resolvedFolderPath
        guard !path.isEmpty else { return }
        
        let url = URL(fileURLWithPath: path)
        let monitor = FolderMonitor(url: url)
        monitor.onChange = { [weak appState] in
            guard let appState = appState, let current = appState.zones.first(where: { $0.id == zoneID }) else { return }
            self.reloadFiles(for: current)
        }
        monitor.start()
        self.folderMonitor = monitor
    }
    
    private func reloadFiles(for zone: ZoneModel) {
        guard zone.type != .app else { return }
        let path = zone.resolvedFolderPath
        guard !path.isEmpty else {
            self.files = []
            return
        }
        self.files = FileManagerService.shared.contentsOfFolder(path: path, manualOrder: zone.manualOrder)
    }
    
    // MARK: - Sorting
    
    private func sortedFiles(_ input: [FileItem], mode: ZoneSortMode) -> [FileItem] {
        switch mode {
        case .manual:
            return input.sorted { $0.manualOrder < $1.manualOrder }
        case .nameAsc:
            return input.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            return input.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .dateDesc:
            return input.sorted { $0.modificationDate > $1.modificationDate }
        case .dateAsc:
            return input.sorted { $0.modificationDate < $1.modificationDate }
        case .sizeDesc:
            return input.sorted { $0.size > $1.size }
        case .sizeAsc:
            return input.sorted { $0.size < $1.size }
        case .kind:
            return input.sorted { $0.kindDescription.localizedCaseInsensitiveCompare($1.kindDescription) == .orderedAscending }
        }
    }
    
    // MARK: - File Actions
    
    private func openFile(_ file: FileItem) {
        NSWorkspace.shared.open(file.url)
    }
    
    private func renameFile(_ file: FileItem, newName: String) {
        guard let current = zone else { return }
        if FileManagerService.shared.renameFile(at: file.url, to: newName) != nil {
            reloadFiles(for: current)
        }
    }
    
    private func deleteFile(_ file: FileItem) {
        guard let current = zone else { return }
        if FileManagerService.shared.trashFile(url: file.url) {
            reloadFiles(for: current)
        }
    }
    
    // MARK: - Drag and Drop Handling
    
    private func handleDrop(providers: [NSItemProvider], zone: ZoneModel) -> Bool {
        var didAccept = false
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    
                    DispatchQueue.main.async {
                        self.processDroppedURL(url, zone: zone)
                    }
                }
                didAccept = true
            }
        }
        return didAccept
    }
    
    private func processDroppedURL(_ url: URL, zone: ZoneModel) {
        if zone.type == .app {
            // App Zone: Only accept .app bundles
            if FileManagerService.shared.isApplication(at: url) {
                if let appItem = FileManagerService.shared.resolveAppInfo(at: url.path) {
                    var updated = zone
                    if !updated.apps.contains(where: { $0.path == appItem.path }) {
                        updated.apps.append(appItem)
                        appState.updateZone(updated)
                    }
                }
            } else {
                // Clear warning banner as specified in recon!
                errorMessageBanner = "App Zones only hold applications (.app). To store files, create a File Zone!"
            }
        } else {
            // File Zone or Folder Zone: Move file into zone folder!
            let destFolder = URL(fileURLWithPath: zone.resolvedFolderPath)
            if FileManagerService.shared.moveFile(from: url, toDirectory: destFolder, collisionOption: .keepBoth) != nil {
                reloadFiles(for: zone)
            }
        }
    }
    
    // MARK: - Window Dragging & Resizing with Snapping
    
    @State private var dragStartFrame: NSRect? = nil
    
    private func handleWindowDrag(translation: CGSize) {
        guard var current = zone else { return }
        if dragStartFrame == nil {
            dragStartFrame = current.frame
        }
        
        guard let start = dragStartFrame else { return }
        var targetRect = NSRect(
            x: start.origin.x + translation.width,
            y: start.origin.y - translation.height, // AppKit coordinate system has 0 at bottom
            width: start.width,
            height: start.height
        )
        
        // Snapping calculations
        let otherFrames = WindowManager.shared.getOtherZoneFrames(excluding: current.id)
        if appState.settings.alignmentMode {
            if let panel = NSApp.windows.first(where: { ($0 as? ZonePanel)?.zoneID == current.id }) as? ZonePanel {
                targetRect = panel.snapFrame(targetRect, otherFrames: otherFrames)
            }
        }
        
        current.frame = targetRect
        appState.updateZone(current)
        WindowManager.shared.updatePanelFrame(id: current.id, newFrame: targetRect)
        
        // Clear dragStart on end or keep tracking
        if abs(translation.width) < 1 && abs(translation.height) < 1 {
            dragStartFrame = nil
        }
    }
    
    private func handleWindowResize(translation: CGSize) {
        guard var current = zone else { return }
        let newWidth = max(220, current.frame.width + translation.width)
        var newHeight = max(140, current.frame.height + translation.height)
        
        if current.isCollapsed {
            newHeight = current.collapsedHeight
        }
        
        var newFrame = current.frame
        newFrame.origin.y -= (newHeight - newFrame.height)
        newFrame.size.width = newWidth
        newFrame.size.height = newHeight
        
        current.frame = newFrame
        current.expandedHeight = newHeight
        appState.updateZone(current)
        WindowManager.shared.updatePanelFrame(id: current.id, newFrame: newFrame)
    }
    
    private func visualEffectMaterial(_ style: String) -> NSVisualEffectView.Material {
        switch style {
        case "ultraThin": return .underWindowBackground
        case "regular": return .headerView
        case "thick": return .popover
        default: return .hudWindow
        }
    }
}

// MARK: - NSVisualEffectView Bridge for SwiftUI

public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Key Event Monitor View for Spacebar QuickLook

public struct KeyEventHandlerView: NSViewRepresentable {
    public var onKeyDown: (NSEvent) -> Bool
    
    public func makeNSView(context: Context) -> KeyView {
        let view = KeyView()
        view.onKeyDown = onKeyDown
        return view
    }
    
    public func updateNSView(_ nsView: KeyView, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
    
    public class KeyView: NSView {
        public var onKeyDown: ((NSEvent) -> Bool)?
        
        public override var acceptsFirstResponder: Bool { true }
        
        public override func keyDown(with event: NSEvent) {
            if let handler = onKeyDown, handler(event) {
                return
            }
            super.keyDown(with: event)
        }
    }
}
