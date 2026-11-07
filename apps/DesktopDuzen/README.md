# DesktopDüzen (DesktopDuzen)

A native macOS productivity utility that organizes your desktop into interactive, customizable "zones" pinned directly to your wallpaper canvas. Full feature parity replica of **Desktop Organizer - File Zones** with all Free and Pro capabilities unlocked.

---

## 🌟 Key Features (Full Normal & Pro Parity)

### 1. Three Zone Types
* **File Zones (Backing Directory in `~/Desktop/Zones`)**:
  - Automatically creates a real folder.
  - Dragging files from the desktop or Finder moves them into the zone folder.
  - Dragging files out provides system drag promises (`NSItemProvider`) to Finder, other apps, or email.
  - Real-time **two-way sync** with the filesystem using kernel event monitoring (`DispatchSourceFileSystemObject`).
  - Safe rename: Renaming a zone on your desktop renames the backing folder on disk safely.
  - Safe delete: Offers 3 explicit choices:
    1. *Move files back to Desktop and remove zone*
    2. *Move zone folder to Trash*
    3. *Keep folder on disk (remove desktop window only)*
  - Intelligent name collision handling (Keep Both with auto-indexing `file 1.ext`, Replace, or Skip).

* **Folder Zones (Quick Access / Folder Portals)**:
  - Mirror any directory on your Mac (e.g., `~/Downloads`, `~/Documents`, custom projects).
  - Security-scoped bookmark persistence across app relaunch.
  - Does not move the source folder; acts as a live desktop portal into that folder.

* **App Zones (Quick Launcher)**:
  - Add apps via right-click or drag-dropping `.app` bundles.
  - 1-click instant app launch.
  - Friendly notification toast if a user drops a non-app file into an App Zone: *"App Zones only store application shortcuts (.app). To store documents, create a File Zone!"*

---

### 2. Canvas & Window Mechanics
* **Pinned Behind All Apps**:
  - Windows are borderless `NSPanel` instances pinned at the desktop layer below normal application windows.
  - Visible on all Spaces (`canJoinAllSpaces`, `stationary`, `ignoresCycle`, `fullScreenAuxiliary`).
  - Does not clutter the Dock or Cmd+Tab app switcher (`LSUIElement = true`).
  - Multi-display recovery: if an external display is disconnected, off-screen zones re-anchor to the visible display.

* **Layout & Sizing**:
  - Freely move by dragging the header or background.
  - Resize handles for corners and edges.
  - **Accordion Rollup / Collapse**: Click the chevron to collapse a zone into just its title bar.
  - **Auto-Expand on Hover (Pro)**: When mouse hovers over a collapsed zone, it automatically unrolls; mouse leave rolls it back up.
  - **Pin on Top (Pro)**: Toggle a zone between Desktop level and Floating/Always-on-top level.
  - **Multi-Tab Zones (Pro)**: Add tabs inside a single zone (e.g. "Active", "Review", "Archive"), backed by subfolders.
  - **Alignment Snapping**: Snaps to neighbor zone edges (left, right, top, bottom) and grid.
  - **Auto-Align All Zones**: Arranges all desktop zones into a clean grid with one click.

---

### 3. Views, Actions & Quick Look
* **View Modes**:
  - **Icon View**: High-resolution thumbnails and file icons (via `QLThumbnailGenerator`).
  - **List View**: Sortable columns for Name, Date Modified, Kind, and Size.
  - Adjustable icon size (32px - 84px), icon spacing, and font size.
  - Sorting: Manual drag-to-sort, Name (A-Z / Z-A), Date Modified, Size, and Kind.
* **Actions**:
  - Double-click to open in default app.
  - Spacebar for instant **Quick Look** preview (`QLPreviewPanel`).
  - Context menu: Open, Quick Look, Reveal in Finder, Rename, Duplicate, Move to Another Zone, Move to Trash.
  - Multi-selection via Shift+click and Cmd+click.

---

### 4. 11 Zone Themes & Customization
1. **Liquid Glass** (Translucent vibrant glass with hairline border)
2. **Dark Frost** (Deep frosted obsidian)
3. **Light Frost** (Clean bright frosted paper)
4. **Slate Titanium** (Industrial space gray)
5. **Minimal Line** (Ultra-thin wireframe outline)
6. **Aurora Glow (Pro)** (Violet/indigo/cyan gradient glow)
7. **Sunset Coral (Pro)** (Warm amber-rose glass)
8. **Emerald Forest (Pro)** (Mint/emerald translucent tone)
9. **Cyberpunk Neon (Pro)** (Electric cyan & magenta border)
10. **Rose Quartz (Pro)** (Soft pink-champagne luxury)
11. **Matrix Terminal (Pro)** (CRT green phosphorescent theme)

---

### 5. Desktop Stickers & Widgets
* **Desktop Stickers**: Add decorative emojis and badges (`🚀`, `☕️`, `⭐️`, `🔥`, `🪴`, etc.) directly on the desktop canvas.
* **Desktop Widgets**:
  - **Clock & Date Widget**: Live digital or analog time.
  - **Mini Calendar Widget**: Month glance with current day highlighted.
  - **Sticky Notes Widget**: Editable quick note with custom color palettes.
  - **System Monitor Widget**: Live CPU load and memory pressure glance.

---

### 6. Smart Auto-Sort Rules
* Monitor `~/Desktop` continuously and automatically move loose files into matching zones:
  - Images (`png`, `jpg`, `heic`, `gif`, `svg`) ➔ Media Zone
  - Documents (`pdf`, `docx`, `txt`, `xlsx`, `md`) ➔ Documents Zone
  - Installers & Archives (`dmg`, `pkg`, `zip`, `tar`) ➔ Downloads Zone
  - Audio & Video (`mp4`, `mov`, `mp3`, `wav`) ➔ Media Zone
* Run on demand or automatically in the background.

---

### 7. Global Search
* Press **Cmd + Shift + Space** or select from the status bar menu to open the Spotlight-style search modal.
* Searches across all zones instantly, displaying matching files, file size, thumbnail, and 1-click reveal in Finder.

---

### 8. Pro Paywall & In-App Simulator
* Pricing plans: Monthly ($1.99), Annual ($19.99), Lifetime ($24.99).
* Includes a testing toggle in Settings and the Paywall to easily toggle between **Free Tier** (limits to 3 zones, basic themes, single tab) and **Pro Tier** (unlimited zones, tabs, widgets, auto-sort, custom themes).

---

## 📦 DMG Installer & Packaging

### Build the DMG:
```bash
cd /Users/darwin/.gemini/antigravity/scratch/DesktopDuzen
./scripts/create_dmg.sh
```
This generates `DesktopDuzen.dmg` with:
- `DesktopDuzen.app` (signed binary with customized App Icon)
- `/Applications` drag-and-drop symlink
- `QuickStart.txt` setup guide
- High-compression UDZO DMG format

### Run the App:
```bash
open DesktopDuzen.app
```

### Run Automated Unit Tests:
```bash
swift test
```
All 9 unit tests verify:
- Theme resolution & custom styling
- Folder sanitization & security scoping
- Multi-tab folder path resolution
- Pro tier entitlement gates
- Export & Import JSON configurations
- File collision handling (`keepBoth`, `replace`, `skip`)
- Auto-sort rule evaluation
- Alignment & neighbor snapping math
