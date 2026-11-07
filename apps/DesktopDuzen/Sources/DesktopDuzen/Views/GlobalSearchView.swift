import SwiftUI
import AppKit

public struct GlobalSearchView: View {
    @EnvironmentObject var appState: AppState
    @State private var query: String = ""
    @State private var searchResults: [SearchResultItem] = []
    @State private var selectedItemID: String? = nil
    
    struct SearchResultItem: Identifiable {
        var id: String { file.path }
        var file: FileItem
        var zoneTitle: String
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                TextField("Search files across all zones...", text: $query)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 15))
                    .onChange(of: query) { newQuery in
                        performSearch(query: newQuery)
                    }
                
                if !query.isEmpty {
                    Button(action: {
                        query = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            
            Divider()
            
            // Results List
            if searchResults.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.2))
                    Text(query.isEmpty ? "Type to search files in any zone" : "No files found matching '\(query)'")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 2) {
                        ForEach(searchResults) { item in
                            let isSelected = (selectedItemID == item.id)
                            HStack(spacing: 10) {
                                FileThumbnailView(file: item.file, size: CGSize(width: 24, height: 24))
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.file.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                                    
                                    HStack(spacing: 6) {
                                        Text(item.zoneTitle)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.cyan)
                                        Text("•")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                        Text(item.file.formattedSize)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    NSWorkspace.shared.selectFile(item.file.path, inFileViewerRootedAtPath: item.file.url.deletingLastPathComponent().path)
                                }) {
                                    Image(systemName: "arrow.up.forward.app")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Reveal in Finder")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.blue.opacity(0.35) : Color.clear)
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItemID = item.id
                            }
                            .simultaneousGesture(
                                TapGesture(count: 2).onEnded {
                                    NSWorkspace.shared.open(item.file.url)
                                }
                            )
                        }
                    }
                    .padding(8)
                }
            }
            
            Divider()
            
            // Footer with Keyboard shortcuts hint
            HStack {
                Text("Double-click to open • Space to preview • Esc to close")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Done") {
                    NSApp.keyWindow?.orderOut(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.04))
        }
        .frame(width: 560, height: 380)
        .background(VisualEffectBlur(material: .popover))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        
        var results: [SearchResultItem] = []
        for zone in appState.zones where zone.type != .app {
            let files = FileManagerService.shared.contentsOfFolder(path: zone.resolvedFolderPath)
            for file in files {
                if file.name.localizedCaseInsensitiveContains(trimmed) {
                    results.append(SearchResultItem(file: file, zoneTitle: zone.title))
                }
            }
        }
        self.searchResults = results
    }
}
