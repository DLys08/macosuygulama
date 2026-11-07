import SwiftUI
import AppKit

public struct StickerView: View {
    @EnvironmentObject var appState: AppState
    let stickerID: UUID
    @State private var isHovering = false

    public var body: some View {
        if let sticker = appState.stickers.first(where: { $0.id == stickerID }) {
            ZStack(alignment: .topTrailing) {
                Text(sticker.content)
                    .font(.system(size: 48))
                    .rotationEffect(.degrees(sticker.rotationDegrees))
                    .scaleEffect(sticker.scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)

                if isHovering {
                    Button {
                        appState.stickers.removeAll { $0.id == stickerID }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.black.opacity(0.65))
                    }
                    .buttonStyle(.plain)
                    .padding(2)
                    .help("Remove sticker")
                }
            }
            .background(WindowDragArea(onDragEnded: { frame in
                WindowManager.shared.commitStickerFrame(id: stickerID, frame: frame)
            }))
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
        }
    }
}
