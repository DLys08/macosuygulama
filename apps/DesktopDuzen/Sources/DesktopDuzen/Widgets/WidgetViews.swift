import SwiftUI
import AppKit
import Combine

/// Widgets use the same theme library and readability engine as zones. Text colours come from
/// the palette, so every theme (and clear mode) stays legible. Sticky notes keep their own
/// note colour for the writing area.
public struct WidgetContainerView: View {
    @EnvironmentObject var appState: AppState
    let widgetID: UUID

    private var dragArea: some View {
        WindowDragArea(onDragEnded: { frame in
            WindowManager.shared.commitWidgetFrame(id: widgetID, frame: frame)
        })
    }

    public var body: some View {
        if let widget = appState.widgets.first(where: { $0.id == widgetID }) {
            let palette = ZonePalette.forWidget(widget)
            VStack(spacing: 0) {
                header(widget, palette: palette)

                Group {
                    switch widget.type {
                    case .clock: ClockWidgetView()
                    case .calendar: CalendarWidgetView()
                    case .quickNote: QuickNoteWidgetView(widgetID: widget.id, initialText: widget.noteContent, colorHex: widget.noteColorHex)
                    case .systemGlance: SystemMonitorWidgetView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Display-only widgets can be dragged from anywhere; the note keeps its text editor.
                .allowsHitTesting(widget.type == .quickNote)
            }
            .background(
                ZStack {
                    ZoneBackgroundView(palette: palette).allowsHitTesting(false)
                    if widget.type != .quickNote { dragArea }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CGFloat(palette.cornerRadius), style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(palette.cornerRadius), style: .continuous)
                    .strokeBorder(palette.showBorder ? palette.border : Color.clear, lineWidth: CGFloat(palette.borderWidth))
                    .allowsHitTesting(false)
            )
            .modifier(ClearModeHalo(active: palette.isClear))
            .environment(\.zonePalette, palette)
            .environment(\.colorScheme, palette.colorScheme)
        }
    }

    private func header(_ widget: DesktopWidget, palette: ZonePalette) -> some View {
        HStack(spacing: 6) {
            Image(systemName: widget.type.iconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(palette.accent)
                .allowsHitTesting(false)
            Text(widget.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(palette.title)
                .lineLimit(1)
                .allowsHitTesting(false)
            Spacer()
            Menu {
                styleMenu(widget)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(palette.primary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .frame(width: 18, height: 18)
            .background(Circle().fill(palette.controlFill))
            .help("Theme, transparency and more")

            Button {
                appState.widgets.removeAll { $0.id == widgetID }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(palette.primary)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(palette.controlFill))
            }
            .buttonStyle(.plain)
            .help("Remove widget")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        // The drag area must be ABOVE the fill; a Color is hit-testable and swallows clicks.
        .background(
            ZStack {
                (palette.isClear ? Color.clear : palette.controlFill.opacity(0.6)).allowsHitTesting(false)
                dragArea
            }
        )
    }

    @ViewBuilder
    private func styleMenu(_ widget: DesktopWidget) -> some View {
        Menu("Theme") {
            ForEach(ThemePresets.categoryOrder, id: \.self) { category in
                let themes = ThemePresets.allThemes.filter { $0.category == category }
                if !themes.isEmpty {
                    Section(category) {
                        ForEach(themes) { theme in
                            Button {
                                if theme.isPro && !appState.isPro { WindowManager.shared.showPaywall(); return }
                                update { $0.themeID = theme.id }
                            } label: {
                                if widget.themeID == theme.id {
                                    Label(theme.name, systemImage: "checkmark")
                                } else {
                                    Text(theme.name)
                                }
                            }
                        }
                    }
                }
            }
        }
        Menu("Transparency") {
            ForEach([(nil, "Theme Default"), (1.0, "Solid (100%)"), (0.75, "75%"), (0.5, "50%"), (0.35, "35%"), (0.15, "15%"), (0.0, "Clear (0%)")] as [(Double?, String)], id: \.1) { value, label in
                Button {
                    update { $0.backgroundOpacity = value }
                } label: {
                    if widget.backgroundOpacity == value {
                        Label(label, systemImage: "checkmark")
                    } else {
                        Text(label)
                    }
                }
            }
        }
        Button(widget.showBorder ? "Hide Border" : "Show Border") {
            update { $0.showBorder.toggle() }
        }
        Divider()
        Button("Reset Style") {
            update {
                $0.themeID = "dark_frost"
                $0.backgroundOpacity = nil
                $0.showBorder = true
            }
        }
        Button("Remove Widget") {
            appState.widgets.removeAll { $0.id == widgetID }
        }
    }

    private func update(_ change: (inout DesktopWidget) -> Void) {
        guard let idx = appState.widgets.firstIndex(where: { $0.id == widgetID }) else { return }
        var copy = appState.widgets[idx]
        change(&copy)
        if copy != appState.widgets[idx] { appState.widgets[idx] = copy }
    }
}

// MARK: - Clock

public struct ClockWidgetView: View {
    @Environment(\.zonePalette) private var palette
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, tolerance: 0.2, on: .main, in: .common).autoconnect()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .medium
        f.dateStyle = .none
        return f
    }()
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return f
    }()

    public var body: some View {
        VStack(spacing: 4) {
            Text(Self.timeFormatter.string(from: now))
                .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(palette.title)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(Self.dateFormatter.string(from: now))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(palette.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .onReceive(timer) { now = $0 }
    }
}

// MARK: - Calendar

public struct CalendarWidgetView: View {
    @Environment(\.zonePalette) private var palette
    @State private var today = Date()
    private let timer = Timer.publish(every: 600, tolerance: 60, on: .main, in: .common).autoconnect()

    private var calendar: Calendar { Calendar.autoupdatingCurrent }

    private var dayCells: [Int?] {
        guard let range = calendar.range(of: .day, in: .month, for: today),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else { return [] }
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading) + range.map { Optional($0) }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    public var body: some View {
        let todayNumber = calendar.component(.day, from: today)
        // Today's badge: primary-coloured disc with the background colour as text (always high contrast).
        let badgeText = palette.isClear ? Color.black : palette.effectiveBackground.color
        VStack(spacing: 6) {
            Text(today.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(palette.title)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 3) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(palette.secondary)
                }
                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        Text("\(day)")
                            .font(.system(size: 10, weight: day == todayNumber ? .bold : .regular).monospacedDigit())
                            .foregroundColor(day == todayNumber ? badgeText : palette.primary)
                            .frame(width: 20, height: 18)
                            .background(Circle().fill(day == todayNumber ? palette.primary : Color.clear))
                    } else {
                        Text(" ").font(.system(size: 10))
                    }
                }
            }
        }
        .padding(10)
        .onReceive(timer) { today = $0 }
    }
}

// MARK: - Sticky note

public struct QuickNoteWidgetView: View {
    @EnvironmentObject var appState: AppState
    let widgetID: UUID
    @State private var text: String
    let colorHex: String

    public init(widgetID: UUID, initialText: String, colorHex: String) {
        self.widgetID = widgetID
        self._text = State(initialValue: initialText)
        self.colorHex = colorHex
    }

    public var body: some View {
        let background = RGBAColor(hex: colorHex)
        let textColor: RGBAColor = RGBAColor.contrastRatio(.black, background) >= RGBAColor.contrastRatio(.white, background) ? RGBAColor(hex: "#1A1A1A") : .white
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Type a note…")
                    .font(.system(size: 12))
                    .foregroundColor(textColor.color.opacity(0.6))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .foregroundColor(textColor.color)
                .padding(8)
                .onChange(of: text) { newText in
                    if let idx = appState.widgets.firstIndex(where: { $0.id == widgetID }), appState.widgets[idx].noteContent != newText {
                        appState.widgets[idx].noteContent = newText
                    }
                }
        }
        .environment(\.colorScheme, textColor == .white ? .dark : .light)
        .background(background.color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .clear, radius: 0) // the note body is never haloed
        .padding(8)
    }
}

// MARK: - System monitor (real values)

public final class SystemMonitorModel: ObservableObject {
    @Published var cpu: Double = 0
    @Published var memory: Double = 0
    private let stats = SystemStats()
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        _ = stats.cpuUsagePercent()
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.sample() }
        timer?.tolerance = 0.5
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        cpu = stats.cpuUsagePercent()
        memory = stats.memoryUsagePercent()
    }

    deinit { timer?.invalidate() }
}

public struct SystemMonitorWidgetView: View {
    @Environment(\.zonePalette) private var palette
    @StateObject private var model = SystemMonitorModel()

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            meter("CPU", value: model.cpu)
            meter("Memory", value: model.memory)
        }
        .padding(14)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func meter(_ title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(palette.secondary)
                Spacer()
                Text("\(Int(value.rounded()))%")
                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                    .foregroundColor(palette.primary)
            }
            ProgressView(value: min(max(value, 0), 100), total: 100)
                .tint(palette.accent)
        }
    }
}
