import SwiftUI

public struct ZoneStylePickerView: View {
    @EnvironmentObject var appState: AppState
    let zoneID: UUID
    
    private var zone: ZoneModel? {
        appState.zones.first(where: { $0.id == zoneID })
    }
    
    public var body: some View {
        if let currentZone = zone {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    Text("Zone Styling & Themes")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    if !appState.isPro {
                        Button("Unlock All (Pro)") {
                            WindowManager.shared.showPaywall()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                
                Divider()
                
                // Theme Swatches
                Text("Select Theme (10+ Styles)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ThemePresets.allThemes) { theme in
                            let isSelected = (currentZone.themeID == theme.id)
                            let isLocked = theme.isPro && !appState.isPro
                            
                            VStack(spacing: 4) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: theme.backgroundHex).opacity(0.85))
                                        .frame(width: 54, height: 44)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(hex: theme.borderHex), lineWidth: isSelected ? 2.5 : 1)
                                        )
                                    
                                    if isLocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.yellow)
                                    } else if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Text(theme.name)
                                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                                    .lineLimit(1)
                                    .frame(maxWidth: 58)
                            }
                            .onTapGesture {
                                if isLocked {
                                    WindowManager.shared.showPaywall()
                                } else {
                                    applyTheme(theme)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Divider()
                
                // Sliders for Fine-Tuning
                VStack(spacing: 10) {
                    // Icon Size
                    HStack {
                        Text("Icon Size:")
                            .font(.system(size: 11))
                            .frame(width: 80, alignment: .leading)
                        Slider(value: Binding(
                            get: { currentZone.iconSize },
                            set: { newVal in
                                var updated = currentZone
                                updated.iconSize = newVal
                                appState.updateZone(updated)
                            }
                        ), in: 32...84, step: 2)
                        Text("\(Int(currentZone.iconSize))px")
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 40, alignment: .trailing)
                    }
                    
                    // Icon Spacing
                    HStack {
                        Text("Spacing:")
                            .font(.system(size: 11))
                            .frame(width: 80, alignment: .leading)
                        Slider(value: Binding(
                            get: { currentZone.iconSpacing },
                            set: { newVal in
                                var updated = currentZone
                                updated.iconSpacing = newVal
                                appState.updateZone(updated)
                            }
                        ), in: 6...28, step: 2)
                        Text("\(Int(currentZone.iconSpacing))px")
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 40, alignment: .trailing)
                    }
                    
                    // Font Size
                    HStack {
                        Text("Font Size:")
                            .font(.system(size: 11))
                            .frame(width: 80, alignment: .leading)
                        Slider(value: Binding(
                            get: { currentZone.fontSize },
                            set: { newVal in
                                var updated = currentZone
                                updated.fontSize = newVal
                                appState.updateZone(updated)
                            }
                        ), in: 9...16, step: 0.5)
                        Text(String(format: "%.1f pt", currentZone.fontSize))
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 45, alignment: .trailing)
                    }
                    
                    // Auto Expand on Hover (Pro)
                    Toggle(isOn: Binding(
                        get: { currentZone.autoExpandOnHover },
                        set: { val in
                            if !appState.canAutoExpand() && val {
                                WindowManager.shared.showPaywall()
                                return
                            }
                            var updated = currentZone
                            updated.autoExpandOnHover = val
                            appState.updateZone(updated)
                        }
                    )) {
                        HStack {
                            Text("Auto-Expand on Hover (Pro)")
                                .font(.system(size: 11))
                            if !appState.isPro {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
            }
            .padding(14)
            .frame(width: 320)
        }
    }
    
    private func applyTheme(_ theme: ZoneTheme) {
        guard var updated = zone else { return }
        updated.themeID = theme.id
        appState.updateZone(updated)
    }
}
