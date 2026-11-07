import SwiftUI
import AppKit

public struct AppZoneView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.zonePalette) private var palette
    let zone: ZoneModel

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 68, maximum: 84), spacing: 10)]
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(zone.apps) { app in
                    AppTileView(app: app, onLaunch: { launch(app) }, onRemove: { remove(app) })
                }
                Button(action: pickNewApp) {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(palette.controlFill)
                                .frame(width: 48, height: 48)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(palette.primary)
                        }
                        Text("Add App")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(palette.secondary)
                            .lineLimit(1)
                    }
                    .padding(6)
                }
                .buttonStyle(.plain)
                .help("Add applications to this zone")
            }
            .padding(12)
        }
    }

    private func launch(_ app: AppItem) {
        let url = URL(fileURLWithPath: app.path)
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                if let error = error {
                    DispatchQueue.main.async { ZoneActions.info("Could Not Open \(app.name)", error.localizedDescription, style: .warning) }
                }
            }
        } else if !app.bundleID.isEmpty, let found = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleID) {
            // The app moved; follow it and remember the new location.
            NSWorkspace.shared.openApplication(at: found, configuration: NSWorkspace.OpenConfiguration())
            appState.mutateZone(id: zone.id) { z in
                if let idx = z.apps.firstIndex(where: { $0.id == app.id }) { z.apps[idx].path = found.path }
            }
        } else {
            ZoneActions.info("Application Not Found", "\(app.name) is no longer at \(app.path).", style: .warning)
        }
    }

    private func remove(_ app: AppItem) {
        appState.mutateZone(id: zone.id) { $0.apps.removeAll { $0.id == app.id } }
    }

    private func pickNewApp() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Add to Zone"
        panel.message = "Choose applications to add to “\(zone.title)”."
        guard panel.runModal() == .OK else { return }
        let items = panel.urls.compactMap { appState.fileService.resolveAppInfo(at: $0.path) }
        appState.mutateZone(id: zone.id) { z in
            for item in items where !z.apps.contains(where: { $0.path == item.path }) {
                var app = item
                app.order = z.apps.count
                z.apps.append(app)
            }
        }
    }
}

public struct AppTileView: View {
    @Environment(\.zonePalette) private var palette
    let app: AppItem
    let onLaunch: () -> Void
    let onRemove: () -> Void
    @State private var isHovering = false

    public var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 6) {
                Image(nsImage: ThumbnailService.shared.appIcon(for: app.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                Text(app.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(palette.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 72)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 10).fill(isHovering ? palette.controlFillStrong : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(app.name)
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Open \(app.name)", action: onLaunch)
            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: app.path)]) }
            Divider()
            Button("Remove Shortcut", action: onRemove)
        }
    }
}
