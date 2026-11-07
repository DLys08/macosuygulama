import SwiftUI
import AppKit

public struct GlobalSearchView: View {
    @EnvironmentObject var appState: AppState
    @State private var query = ""
    @State private var results: [SearchResultItem] = []
    @State private var selectedID: String?
    @FocusState private var fieldFocused: Bool

    struct SearchResultItem: Identifiable {
        var id: String { file.path }
        var file: FileItem
        var zoneTitle: String
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                TextField("Search files in all zones", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .focused($fieldFocused)
                    .onSubmit(openSelected)
                    .onChange(of: query) { performSearch($0) }
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear")
                }
            }
            .padding(14)

            Divider()

            if results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    Text(query.isEmpty ? "Type to search file names in every zone" : "No files match “\(query)”")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 2) {
                        ForEach(results) { item in
                            resultRow(item)
                        }
                    }
                    .padding(8)
                }
            }

            Divider()

            HStack {
                Text("Return opens the selected file • Esc closes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Done") { WindowManager.shared.closeSearch() }
                    .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 560, height: 380)
        .background(VisualEffectBlur(material: .popover))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1))
        .onAppear { fieldFocused = true }
    }

    private func resultRow(_ item: SearchResultItem) -> some View {
        let isSelected = selectedID == item.id
        return HStack(spacing: 10) {
            FileThumbnailView(file: item.file, size: CGSize(width: 24, height: 24))
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.file.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? Color(nsColor: .alternateSelectedControlTextColor) : .primary)
                    .lineLimit(1)
                Text("\(item.zoneTitle) • \(item.file.formattedSize)")
                    .font(.caption)
                    .foregroundColor(isSelected ? Color(nsColor: .alternateSelectedControlTextColor).opacity(0.85) : .secondary)
            }
            Spacer()
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.file.url])
            } label: {
                Image(systemName: "arrow.up.forward.app")
                    .foregroundColor(isSelected ? Color(nsColor: .alternateSelectedControlTextColor) : .secondary)
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(isSelected ? Color(nsColor: .selectedContentBackgroundColor) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { NSWorkspace.shared.open(item.file.url) }
        .onTapGesture { selectedID = item.id }
    }

    private func openSelected() {
        if let item = results.first(where: { $0.id == selectedID }) ?? results.first {
            NSWorkspace.shared.open(item.file.url)
            WindowManager.shared.closeSearch()
        }
    }

    private func performSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            selectedID = nil
            return
        }
        var found: [SearchResultItem] = []
        var seen = Set<String>()
        for zone in appState.zones where zone.type != .app {
            for file in appState.fileService.contentsOfFolder(path: zone.resolvedFolderPath)
            where file.name.localizedCaseInsensitiveContains(trimmed) && seen.insert(file.path).inserted {
                found.append(SearchResultItem(file: file, zoneTitle: zone.title))
            }
            if found.count >= 300 { break }
        }
        results = found
        if !found.contains(where: { $0.id == selectedID }) { selectedID = found.first?.id }
    }
}
