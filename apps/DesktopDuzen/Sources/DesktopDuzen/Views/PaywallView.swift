import SwiftUI

public struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPlan: ProTierPlan = .lifetime
    @State private var purchaseSuccessAlert: Bool = false
    
    public var body: some View {
        VStack(spacing: 18) {
            // Header
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    Text("DesktopDüzen Pro")
                        .font(.system(size: 24, weight: .bold))
                }
                
                Text("Transform your Mac desktop into a clean, powerful command center.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
            
            // Feature List
            VStack(alignment: .leading, spacing: 10) {
                featureRow(icon: "square.grid.3x3.fill", title: "Unlimited Zones", subtitle: "Break free from the 3-zone limit")
                featureRow(icon: "folder.fill.badge.plus", title: "Multi-Tab Zones", subtitle: "Tabbed subfolders inside a single zone")
                featureRow(icon: "pin.fill", title: "Pin on Top & Auto-Hover Expand", subtitle: "Floating access and accordion unrolling")
                featureRow(icon: "paintpalette.fill", title: "All 10+ Premium Themes", subtitle: "Cyberpunk, Aurora, Emerald, Liquid Glass & custom tuning")
                featureRow(icon: "wand.and.stars", title: "Widgets & Desktop Stickers", subtitle: "Clocks, calendars, sticky notes, and badges")
                featureRow(icon: "bolt.fill", title: "Smart Auto-Sort Rules", subtitle: "Automatically routes desktop clutter by extension")
                featureRow(icon: "magnifyingglass", title: "Global Search Across All Zones", subtitle: "Instant Spotlight-style lookup")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            
            // Plan Cards
            HStack(spacing: 12) {
                ForEach(ProTierPlan.allCases, id: \.self) { plan in
                    let isSelected = (selectedPlan == plan)
                    VStack(spacing: 6) {
                        if let badge = plan.savingsBadge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        } else {
                            Text(" ")
                                .font(.system(size: 9))
                                .padding(.vertical, 2)
                        }
                        
                        Text(plan.rawValue)
                            .font(.system(size: 14, weight: .bold))
                        
                        Text(plan.priceString)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color.blue.opacity(0.18) : Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPlan = plan
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Purchase / Action Buttons
            VStack(spacing: 10) {
                Button(action: purchaseSelectedPlan) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text(appState.isPro ? "Pro Active (Switch Plan)" : "Unlock DesktopDüzen Pro")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                HStack(spacing: 20) {
                    Button("Restore Purchases") {
                        appState.license.isPro = true
                        purchaseSuccessAlert = true
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    
                    Divider().frame(height: 12)
                    
                    // Testing toggle so user and developer can freely toggle Pro features
                    Button(appState.isPro ? "Simulate Free Tier" : "Simulate Pro Tier") {
                        appState.license.isPro.toggle()
                        appState.license.isMockProActive = appState.license.isPro
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(width: 580)
        .padding(12)
        .alert("Pro Membership Activated!", isPresented: $purchaseSuccessAlert) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("All normal and Pro features are fully unlocked.")
        }
    }
    
    @ViewBuilder
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.cyan)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.green)
        }
    }
    
    private func purchaseSelectedPlan() {
        appState.license.isPro = true
        appState.license.activePlan = selectedPlan
        appState.license.isMockProActive = true
        purchaseSuccessAlert = true
    }
}
