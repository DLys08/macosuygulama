import SwiftUI
import AppKit

public struct StickerView: View {
    @EnvironmentObject var appState: AppState
    let stickerID: UUID
    @State private var isHovering: Bool = false
    
    private var sticker: DesktopSticker? {
        appState.stickers.first(where: { $0.id == stickerID })
    }
    
    public var body: some View {
        if let current = sticker {
            ZStack(alignment: .topTrailing) {
                Text(current.content)
                    .font(.system(size: 48))
                    .padding(12)
                    .rotationEffect(.degrees(current.rotationDegrees))
                    .scaleEffect(current.scale)
                
                if isHovering {
                    Button(action: {
                        appState.stickers.removeAll(where: { $0.id == stickerID })
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(4)
                }
            }
            .contentShape(Rectangle())
            .onHover { hover in
                self.isHovering = hover
            }
        }
    }
}
