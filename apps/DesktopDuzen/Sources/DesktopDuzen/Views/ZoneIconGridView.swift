import SwiftUI
import AppKit

public struct ZoneIconGridView: View {
    @ObservedObject var appState: AppState
    let zone: ZoneModel
    let files: [FileItem]
    @Binding var selectedFilePaths: Set<String>
    let onFileDoubleClicked: (FileItem) -> Void
    let onFileRenamed: (FileItem, String) -> Void
    let onFileDeleted: (FileItem) -> Void
    
    @State private var fileBeingRenamed: FileItem? = nil
    @State private var renameText: String = ""
    
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: CGFloat(zone.iconSize + 24), maximum: CGFloat(zone.iconSize + 48)), spacing: CGFloat(zone.iconSpacing))]
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns, spacing: CGFloat(zone.iconSpacing)) {
                ForEach(files) { file in
                    let isSelected = selectedFilePaths.contains(file.path)
                    
                    VStack(spacing: 4) {
                        // File Thumbnail / Icon
                        FileThumbnailView(file: file, size: CGSize(width: zone.iconSize, height: zone.iconSize))
                            .frame(width: CGFloat(zone.iconSize), height: CGFloat(zone.iconSize))
                        
                        // File Name / Inline Rename
                        if fileBeingRenamed?.id == file.id {
                            TextField("Name", text: $renameText, onCommit: {
                                commitRename(file)
                            })
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: CGFloat(zone.fontSize)))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(3)
                        } else {
                            Text(file.name)
                                .font(.system(size: CGFloat(zone.fontSize), weight: .medium))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(maxWidth: CGFloat(zone.iconSize + 28))
                        }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.blue.opacity(0.35) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleSelection(file: file)
                    }
                    .simultaneousGesture(
                        TapGesture(count: 2).onEnded {
                            onFileDoubleClicked(file)
                        }
                    )
                    .contextMenu {
                        fileContextMenu(for: file)
                    }
                    .onDrag {
                        NSItemProvider(object: file.url as NSURL)
                    }
                }
            }
            .padding(10)
        }
    }
    
    // MARK: - Selection & Rename
    
    private func handleSelection(file: FileItem) {
        let flags = NSEvent.modifierFlags
        if flags.contains(.command) {
            if selectedFilePaths.contains(file.path) {
                selectedFilePaths.remove(file.path)
            } else {
                selectedFilePaths.insert(file.path)
            }
        } else if flags.contains(.shift) {
            selectedFilePaths.insert(file.path)
        } else {
            selectedFilePaths = [file.path]
        }
    }
    
    private func commitRename(_ file: FileItem) {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != file.name {
            onFileRenamed(file, trimmed)
        }
        fileBeingRenamed = nil
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func fileContextMenu(for file: FileItem) -> some View {
        Button("Open") {
            onFileDoubleClicked(file)
        }
        
        Button("Quick Look Preview (Space)") {
            QuickLookManager.shared.preview(urls: [file.url])
        }
        
        Button("Reveal in Finder") {
            NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: file.url.deletingLastPathComponent().path)
        }
        
        Divider()
        
        Button("Rename...") {
            renameText = file.name
            fileBeingRenamed = file
        }
        
        Button("Duplicate") {
            let parent = file.url.deletingLastPathComponent()
            _ = FileManagerService.shared.moveFile(from: file.url, toDirectory: parent, collisionOption: .keepBoth)
        }
        
        Menu("Move to Zone") {
            ForEach(appState.zones.filter { $0.id != zone.id && $0.type != .app }) { targetZone in
                Button(targetZone.title) {
                    let dest = URL(fileURLWithPath: targetZone.resolvedFolderPath)
                    _ = FileManagerService.shared.moveFile(from: file.url, toDirectory: dest)
                }
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            onFileDeleted(file)
        }) {
            Label("Move to Trash", systemImage: "trash")
        }
    }
}

// MARK: - File Thumbnail View

public struct FileThumbnailView: View {
    let file: FileItem
    let size: CGSize
    @State private var image: NSImage?
    
    public var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(file.isDirectory ? .cyan : .gray)
            }
        }
        .onAppear {
            ThumbnailService.shared.thumbnail(for: file.url, size: size) { thumb in
                self.image = thumb
            }
        }
    }
}
