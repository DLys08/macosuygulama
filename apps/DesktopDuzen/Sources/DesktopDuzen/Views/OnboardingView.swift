import SwiftUI

public struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: Int = 0
    
    public var body: some View {
        VStack(spacing: 24) {
            if currentStep == 0 {
                // Step 0: Introduction
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Welcome to DesktopDüzen")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("A clean workspace for your Mac desktop.\nTidy files into beautiful, interactive zones pinned directly to your wallpaper.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 20) {
                    featureBadge(icon: "folder.fill", title: "File Zones", desc: "Drag files in to organize")
                    featureBadge(icon: "arrow.up.right.square", title: "Folder Zones", desc: "Quick access portals")
                    featureBadge(icon: "square.grid.2x2", title: "App Zones", desc: "1-click app launcher")
                }
                .padding(.vertical, 8)
                
                Button("Continue") {
                    currentStep = 1
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
            } else if currentStep == 1 {
                // Step 1: Desktop Folder Access
                VStack(spacing: 14) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                    
                    Text("Desktop Permissions")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("DesktopDüzen creates and manages zone folders inside your Desktop folder so your files remain 100% yours and synchronized in Finder.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(FileManager.default.isWritableFile(atPath: appState.fileService.desktopURL.path) ? "Desktop is writable. Zone folders live in ~/Desktop/Zones" : "Desktop not writable yet. Allow access in System Settings > Privacy & Security > Files and Folders")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(10)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                HStack(spacing: 16) {
                    Button("Back") {
                        currentStep = 0
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Get Started") {
                        appState.settings.hasCompletedOnboarding = true
                        WindowManager.shared.closeOnboarding()
                        WindowManager.shared.showHub()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .padding(32)
        .frame(width: 540, height: 380)
    }
    
    @ViewBuilder
    private func featureBadge(icon: String, title: String, desc: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.accentColor)
            Text(title)
                .font(.system(size: 12, weight: .bold))
            Text(desc)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 130)
        .padding(10)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }
}
