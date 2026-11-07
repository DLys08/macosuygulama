import SwiftUI
import AppKit

/// About screen in the same layout as AleClip: header, "Open Source" card, "Follow & Support" card.
/// Link text uses the system link colour so it stays above 4.5:1 in Light and Dark Mode.
public struct AboutView: View {
    public init() {}

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "2026"
        return "Version \(version) (\(build))"
    }

    public var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 68, height: 68)
                    .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                VStack(spacing: 3) {
                    Text("DesktopDüzen")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text(versionString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Text("A modern, native desktop organizer for macOS.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 4)

            DDOpenSourceCard()
            DDFollowSupportCard()
        }
        .frame(maxWidth: 460)
        .padding(16)
    }
}

private enum Links {
    static let github = URL(string: "https://github.com/themanoftalent")!
    static let sponsor = URL(string: "https://github.com/sponsors/themanoftalent")!
    static let coffee = URL(string: "https://buymeacoffee.com/themanoftalent")!
}

private struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1))
            )
    }
}

struct DDOpenSourceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.0, green: 0.40, blue: 0.90))
                        .frame(width: 24, height: 24)
                    Text("{}")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                Text("Open Source | Free to Fork & Use")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            Text("Feel free to fork, modify, use, and contribute!")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                row("Developed by:", "SoftAI Yazılım")
                row("Developer:", "Assoc. Prof. Dr. Mehmet Akif Cifci")
                HStack(spacing: 6) {
                    Text("GitHub:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Link("@themanoftalent", destination: Links.github)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(nsColor: .linkColor))
                }
            }
            .padding(.top, 2)
        }
        .modifier(CardBackground())
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}

struct DDFollowSupportCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("❤️").font(.system(size: 16))
                Text("Follow & Support")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            Text("If you find this project useful, star the repository, follow me, or buy me a coffee! Your support helps keep future projects free and open-source.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                pill(url: Links.github, tint: Color(red: 0.0, green: 0.48, blue: 1.0)) {
                    Text("</>")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(nsColor: .linkColor))
                } label: { Text("GitHub") }
                pill(url: Links.sponsor, tint: .red) {
                    Text("❤️").font(.system(size: 12))
                } label: { Text("Sponsor Me") }
                pill(url: Links.coffee, tint: .orange) {
                    Text("☕").font(.system(size: 12))
                } label: { Text("Buy Me a Coffee") }
            }
            .padding(.top, 2)
        }
        .modifier(CardBackground())
    }

    private func pill<Icon: View, Label: View>(url: URL, tint: Color, @ViewBuilder icon: () -> Icon,
                                              @ViewBuilder label: () -> Label) -> some View {
        Link(destination: url) {
            HStack(spacing: 6) {
                icon()
                label()
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(tint.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(tint.opacity(0.4), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(url.absoluteString)
    }
}
