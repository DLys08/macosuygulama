import SwiftUI
import AppKit

public struct ZoneStylePickerView: View {
    @EnvironmentObject var appState: AppState
    let zoneID: UUID

    public var body: some View {
        if let zone = appState.zone(id: zoneID) {
            content(zone)
                .padding(14)
                .frame(width: 360)
        }
    }

    private func content(_ zone: ZoneModel) -> some View {
        let palette = ZonePalette.forZone(zone)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Zone Style")
                    .font(.headline)
                Spacer()
                if !appState.isPro {
                    Button("Unlock All") { WindowManager.shared.showPaywall() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }

            Text("Theme")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(ThemePresets.categoryOrder, id: \.self) { category in
                        let themes = ThemePresets.allThemes.filter { $0.category == category }
                        if !themes.isEmpty {
                            Text(category)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 66), spacing: 8)], spacing: 8) {
                                ForEach(themes) { theme in swatch(theme, zone: zone) }
                            }
                        }
                    }
                }
                .padding(.trailing, 6)
            }
            .frame(height: 250)

            Divider()

            Text("Background")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            HStack {
                ColorPicker("Custom colour", selection: Binding(
                    get: { Color(hex: zone.customBackgroundHex ?? ThemePresets.theme(for: zone.themeID).backgroundHex) },
                    set: { newColor in
                        let rgb = NSColor(newColor).usingColorSpace(.sRGB) ?? .black
                        let hex = RGBAColor(r: Double(rgb.redComponent), g: Double(rgb.greenComponent), b: Double(rgb.blueComponent)).hexString
                        appState.mutateZone(id: zoneID) { $0.customBackgroundHex = hex }
                    }
                ), supportsOpacity: false)
                Spacer()
                Button("Reset to Theme") {
                    appState.mutateZone(id: zoneID) {
                        $0.customBackgroundHex = nil
                        $0.customBackgroundOpacity = nil
                        $0.showBorder = true
                        $0.showShadow = true
                    }
                }
                .controlSize(.small)
                .disabled(zone.customBackgroundHex == nil && zone.customBackgroundOpacity == nil && zone.showBorder && zone.showShadow)
            }

            sliderRow("Opacity", value: Binding(
                get: { zone.customBackgroundOpacity ?? ThemePresets.theme(for: zone.themeID).backgroundOpacity },
                set: { v in appState.mutateZone(id: zoneID) { $0.customBackgroundOpacity = v } }
            ), range: 0.0...1.0, step: 0.05, format: { $0 <= 0.001 ? "Clear" : "\(Int(($0 * 100).rounded()))%" })

            HStack(spacing: 16) {
                Toggle("Border", isOn: Binding(get: { zone.showBorder }, set: { v in appState.mutateZone(id: zoneID) { $0.showBorder = v } }))
                Toggle("Shadow", isOn: Binding(get: { zone.showShadow }, set: { v in appState.mutateZone(id: zoneID) { $0.showShadow = v } }))
                Spacer()
                Button("Fully Transparent") {
                    appState.mutateZone(id: zoneID) {
                        $0.customBackgroundOpacity = 0
                        $0.showBorder = false
                        $0.showShadow = false
                    }
                }
                .controlSize(.small)
            }
            .font(.system(size: 11))

            if palette.isClear {
                Text("Clear mode: no fill or blur. Labels get a shadow so they stay readable on any wallpaper.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Live preview of the text colours the zone will use.
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").foregroundColor(palette.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Readable text").font(.system(size: 12, weight: .bold)).foregroundColor(palette.title)
                    Text(palette.isClear ? "Shadowed labels (clear mode)" : String(format: "Contrast %.1f : 1", palette.primaryContrast))
                        .font(.system(size: 10)).foregroundColor(palette.secondary)
                }
                Spacer()
                if !palette.isClear && palette.tintOpacity > (zone.customBackgroundOpacity ?? ThemePresets.theme(for: zone.themeID).backgroundOpacity) + 0.01 {
                    Text("Opacity raised for legibility")
                        .font(.system(size: 9)).foregroundColor(palette.secondary)
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(palette.tint.color.opacity(palette.tintOpacity)))
            .environment(\.colorScheme, palette.colorScheme)

            Divider()

            sliderRow("Icon size", value: Binding(get: { zone.iconSize }, set: { v in appState.mutateZone(id: zoneID) { $0.iconSize = v } }),
                      range: 32...84, step: 2, format: { "\(Int($0)) px" })
            sliderRow("Spacing", value: Binding(get: { zone.iconSpacing }, set: { v in appState.mutateZone(id: zoneID) { $0.iconSpacing = v } }),
                      range: 6...28, step: 2, format: { "\(Int($0)) px" })
            sliderRow("Font size", value: Binding(get: { zone.fontSize }, set: { v in appState.mutateZone(id: zoneID) { $0.fontSize = v } }),
                      range: 9...16, step: 0.5, format: { String(format: "%.1f pt", $0) })

            Toggle("Expand when the pointer hovers (collapsed zones)", isOn: Binding(
                get: { zone.autoExpandOnHover },
                set: { value in
                    if value && !appState.canAutoExpand() { WindowManager.shared.showPaywall(); return }
                    appState.mutateZone(id: zoneID) { $0.autoExpandOnHover = value }
                }
            ))
            .font(.system(size: 11))
        }
    }

    private func swatch(_ theme: ZoneTheme, zone: ZoneModel) -> some View {
        let isSelected = zone.themeID == theme.id
        let isLocked = theme.isPro && !appState.isPro
        let p = ZonePalette.make(theme: theme)
        return Button {
            if isLocked { WindowManager.shared.showPaywall(); return }
            appState.mutateZone(id: zoneID) { $0.themeID = theme.id }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    ZoneBackgroundView(palette: p, preview: true)
                        .environment(\.colorScheme, p.colorScheme)
                        .frame(width: 60, height: 42)
                        .overlay(RoundedRectangle(cornerRadius: min(10, CGFloat(p.cornerRadius)), style: .continuous)
                            .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: isSelected ? 2.5 : 1))
                    if isLocked {
                        Image(systemName: "lock.fill").font(.system(size: 12)).foregroundColor(p.primary)
                    } else {
                        Text("Aa").font(.system(size: 13, weight: .bold)).foregroundColor(p.title)
                    }
                }
                Text(theme.name)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: 66)
            }
        }
        .buttonStyle(.plain)
        .help(isLocked ? "\(theme.name) (Pro)" : theme.name)
    }

    private func sliderRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double,
                           format: @escaping (Double) -> String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .frame(width: 70, alignment: .leading)
            Slider(value: value, in: range, step: step)
            Text(format(value.wrappedValue))
                .font(.system(size: 11).monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 52, alignment: .trailing)
        }
    }
}
