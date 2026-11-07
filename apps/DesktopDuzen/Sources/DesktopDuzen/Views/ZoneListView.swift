import SwiftUI
import AppKit

public struct ZoneListView: View {
    @ObservedObject var appState: AppState
    let zone: ZoneModel
    let files: [FileItem]
    @Binding var selectedFilePaths: Set<String>
    let onFileDoubleClicked: (FileItem) -> Void
    let onFileRenamed: (FileItem, String) -> Void
    let onFileDeleted: (FileItem) -> Void
    
    @State private var fileBeingRenamed: FileItem? = nil
    @State private var renameText: String = ""
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 8) {
                Text("Name")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Date Modified")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 90, alignment: .trailing)
                
                Text("Kind")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 70, alignment: .leading)
                
                Text("Size")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 55, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.04))
            
            Divider().background(Color.white.opacity(0.1))
            
            // File Rows
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 1) {
                    ForEach(files) { file in
                        let isSelected = selectedFilePaths.contains(file.path)
                        
                        HStack(spacing: 8) {
                            // File Icon
                            FileThumbnailView(file: file, size: CGSize(width: 18, height: 18))
                                .frame(width: 18, height: 18)
                            
                            // Name
                            if fileBeingRenamed?.id == file.id {
                                TextField("Name", text: $renameText, onCommit: {
                                    commitRename(file)
                                })
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: CGFloat(zone.fontSize)))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .background(Color.blue.opacity(0.6))
                                .cornerRadius(3)
                            } else {
                                Text(file.name)
                                    .font(.system(size: CGFloat(zone.fontSize), weight: .medium))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Date
                            Text(file.formattedDate)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 90, alignment: .trailing)
                                .lineLimit(1)
                            
                            // Kind
                            Text(file.kindDescription)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 70, alignment: .leading)
                                .lineLimit(1)
                            
                            // Size
                            Text(file.formattedSize)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 55, alignment: .trailing)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? Color.blue.opacity(0.35) : Color.clear)
                        .cornerRadius(4)
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
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
        }
    }
    
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
