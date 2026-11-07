import SwiftUI
import AppKit

/// Draws a zone's glass: blur material, tint (flat or gradient), specular sheen and the bright
/// top-edge highlight of the liquid glass themes. Shared by zones and theme swatches.
public struct ZoneBackgroundView: View {
    let palette: ZonePalette
    /// Swatches skip the live blur and draw the material base colour instead.
    var preview: Bool = false

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: CGFloat(palette.cornerRadius), style: .continuous)
        ZStack {
            // Near-invisible floor: a fully transparent window lets clicks and file drops fall
            // through to the desktop, so clear zones keep a 1 % layer to stay interactive.
            Color.black.opacity(0.012)
            if palette.isClear {
                palette.tintGradient
            } else if preview {
                (palette.isDark ? ZonePalette.darkMaterialBase : ZonePalette.lightMaterialBase).color
            } else {
                VisualEffectBlur(material: palette.material, appearance: palette.appearance)
            }
            if !palette.isClear { palette.tintGradient }
            if palette.sheen > 0 {
                // Specular sheen: strongest at the top, fading out by mid-height.
                LinearGradient(stops: [
                    .init(color: Color.white.opacity(palette.sheen), location: 0),
                    .init(color: Color.white.opacity(palette.sheen * 0.35), location: 0.22),
                    .init(color: Color.white.opacity(0), location: 0.55)
                ], startPoint: .top, endPoint: .bottom)
            }
        }
        .clipShape(shape)
        .overlay {
            if palette.glassHighlight {
                // Light catching the rim: bright on the top edge, fading down the sides.
                shape.strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.75), Color.white.opacity(0.12), Color.white.opacity(0.05), Color.white.opacity(0.25)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.2)
                    .blendMode(.plusLighter)
            }
        }
    }
}
