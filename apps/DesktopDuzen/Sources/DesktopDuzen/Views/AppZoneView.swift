import SwiftUI
import AppKit

public struct AppZoneView: View {
    @ObservedObject var appState: AppState
    let zone: ZoneModel
    
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 64, maximum: 80), spacing: 12)]
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(zone.apps) { app in
                    AppTileView(app: app) {
                        launchApp(app)
                    } onRemove: {
                        removeApp(app)
                    }
                }
                
                // Add App Button
                Button(action: pickNewApp) {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text("Add App")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
        }
    }
    
    private func launchApp(_ app: AppItem) {
        let url = URL(fileURLWithPath: app.path)
        NSWorkspace.shared.open(url)
    }
    
    private func removeApp(_ app: AppItem) {
        var updated = zone
        updated.apps.removeAll(where: { $0.id == app.id })
        appState.updateZone(updated)
    }
    
    private func pickNewApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Add to Zone"
        panel.message = "Select applications to add to '\(zone.title)':"
        
        if panel.runModal() == .OK {
            var updated = zone
            for url in panel.urls {
                if let item = FileManagerService.shared.resolveAppInfo(at: url.path) {
                    if !updated.apps.contains(where: { $0.path == item.path }) {
                        updated.apps.append(item)
                    }
                }
            }
            appState.updateZone(updated)
        }
    }
}

public struct AppTileView: View {
    let app: AppItem
    let onLaunch: () -> Void
    let onRemove: () -> Void
    
    @State private var isHovering: Bool = false
    
    public var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 6) {
                // App Icon
                Image(nsImage: ThumbnailService.shared.appIcon(for: app.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .scaleEffect(isHovering ? 1.08 : 1.0)
                    .shadow(color: isHovering ? Color.white.opacity(0.3) : Color.black.opacity(0.4), radius: isHovering ? 6 : 2)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovering)
                
                // App Name
                Text(app.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .frame(maxWidth: 68)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovering ? Color.white.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            self.isHovering = hovering
        }
        .contextMenu {
            Button("Launch \(app.name)") {
                onLaunch()
            }
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(app.path, inFileViewerRootedAtPath: "/Applications")
            }
            Divider()
            Button(role: .destructive, action: onRemove) {
                Label("Remove Shortcut", systemImage: "trash")
            }
        }
    }
}
