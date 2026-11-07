import SwiftUI
import AppKit
import Combine

/// Widgets always draw on a dark glass background (the panel is forced to Dark Aqua),
/// so light text is guaranteed to have contrast. Sticky notes use dark text on a light note.
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
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: widget.type.iconName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .allowsHitTesting(false)
                    Text(widget.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .allowsHitTesting(false)
                    Spacer()
                    Button {
                        appState.widgets.removeAll { $0.id == widgetID }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .help("Remove widget")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                // The drag area must be ABOVE the fill: a Color is hit-testable and used to
                // swallow every click, so widgets could not be moved at all.
                .background(
                    ZStack {
                        Color.black.opacity(0.25).allowsHitTesting(false)
                        dragArea
                    }
                )

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
                    VisualEffectBlur(material: .hudWindow, appearance: NSAppearance(named: .darkAqua))
                        .allowsHitTesting(false)
                    Color.black.opacity(0.45).allowsHitTesting(false)
                    if widget.type != .quickNote { dragArea }
                }
            )
            .help(widget.type == .quickNote ? "" : "Drag to move • drag an edge to resize")
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
            .environment(\.colorScheme, .dark)
        }
    }
}

// MARK: - Clock

public struct ClockWidgetView: View {
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
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(Self.dateFormatter.string(from: now))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding(12)
        .onReceive(timer) { now = $0 }
    }
}

// MARK: - Calendar

public struct CalendarWidgetView: View {
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
        VStack(spacing: 6) {
            Text(today.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 3) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        Text("\(day)")
                            .font(.system(size: 10, weight: day == todayNumber ? .bold : .regular).monospacedDigit())
                            .foregroundColor(day == todayNumber ? .black : .white)
                            .frame(width: 20, height: 18)
                            .background(Circle().fill(day == todayNumber ? Color.white : Color.clear))
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
        // Pick black or white text from the note colour's luminance.
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
        _ = stats.cpuUsagePercent() // prime the delta
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
    @StateObject private var model = SystemMonitorModel()

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            meter("CPU", value: model.cpu, tint: .green)
            meter("Memory", value: model.memory, tint: .cyan)
        }
        .padding(14)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func meter(_ title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("\(Int(value.rounded()))%")
                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                    .foregroundColor(.white)
            }
            ProgressView(value: min(max(value, 0), 100), total: 100)
                .tint(tint)
        }
    }
}
