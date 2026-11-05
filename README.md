# macOS Uygulama (macosuygulama.vercel.app)

Official website and application hub for native, open-source macOS software developed by **Mehmet Akif Çifçi** ([@themanoftalent](https://github.com/themanoftalent)).

Inspired by modern app showcase portals, this hub presents a curated suite of high-performance, local-first macOS tools.

---

## 🌟 Featured Applications

| App | Category | Tech | Key Highlights |
|---|---|---|---|
| **[AlePdf](https://github.com/themanoftalent/alepdf)** | PDF & Document Studio | Rust, egui | In-place editing, annotations, page organizing, form filling & digital signing. |
| **[Temizale](https://github.com/themanoftalent/Temizale)** | System & Cleaner | Swift 6, SwiftUI | Fast cache cleaning, orphaned file scrubber, and app uninstaller (v2.2.0 DMG). |
| **[Miknatizale](https://github.com/themanoftalent/Miknatizale)** | Window Management | Swift 6, AppKit | Pixel-perfect native window snapping, halves, thirds, and quadrants. |
| **[RecordAle](https://github.com/themanoftalent/RecordAle)** | Screen & Video Studio | TypeScript, Motion Canvas | Studio walkthrough recording with auto-zoom, smooth cursor tracking & frames. |
| **[Foldale](https://github.com/themanoftalent/foldale)** | File Manager | Rust, Dual-Pane | Dual-pane keyboard-driven workflow with async Rust transfer engine. |
| **[Saklamac Pro](https://github.com/themanoftalent/saklamac)** | Menu Bar Manager | Swift 6, SwiftUI | Notch-safe status item manager with floating overflow shelf and quick search. |
| **[AleClip](https://github.com/themanoftalent/AleClip)** | Clipboard History | Swift 6, AppKit | Fast, encrypted, local-first clipboard search and instant paste tool. |
| **[AleCal](https://github.com/themanoftalent/AleCal)** | Menu Bar Calendar | SwiftUI | Glassmorphic calendar with 1-click Google Meet / Zoom join and live countdowns. |
| **[AleBar](https://github.com/themanoftalent/Ale_Bar)** | Menu Bar Customizer | Swift 6 | Menu bar organizer, custom styling engine, and keyboard command palette. |
| **[AleDesk](https://github.com/themanoftalent/AleDesk)** | Remote Desktop | Rust & C++ | Ultra-low latency, secure P2P desktop control and file transfer. |

---

## 🚀 Architectural Pillars

1. **Native & Blazing Fast**: Engineered with Swift and Rust for Apple Silicon and Universal architectures.
2. **Private by Default**: 100% local-first data processing. Zero tracking, compulsory accounts, or external uploads.
3. **Authentic macOS Feel**: Seamless alignment with macOS Human Interface Guidelines.
4. **Open Source & Free**: Fully transparent codebases available on GitHub.
5. **Low Memory & Battery Friendly**: Low footprint background daemons.
6. **Agent & CLI Ready**: Automation-friendly interfaces and Model Context Protocol (MCP) support.

---

## 🛠 Local Preview

To preview the portal locally:

```sh
python3 -m http.server 4173 --bind 127.0.0.1 --directory dist
```

Then visit `http://127.0.0.1:4173/` or `http://127.0.0.1:4173/tr/`.

---

## 🌐 Deployment

Deployed via Vercel:
- **Production URL**: [macosuygulama.vercel.app](https://macosuygulama.vercel.app)
- **Framework Preset**: Other (Static)
- **Output Directory**: `dist`
