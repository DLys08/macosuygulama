import SwiftUI
import AppKit
import Combine

public struct WidgetContainerView: View {
    @EnvironmentObject var appState: AppState
    let widgetID: UUID
    
    private var widget: DesktopWidget? {
        appState.widgets.first(where: { $0.id == widgetID })
    }
    
    public var body: some View {
        if let currentWidget = widget {
            VStack(spacing: 0) {
                // Header (Draggable)
                HStack {
                    Image(systemName: currentWidget.type.iconName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    Text(currentWidget.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Button(action: {
                        appState.widgets.removeAll(where: { $0.id == widgetID })
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.2))
                
                // Widget Body
                Group {
                    switch currentWidget.type {
                    case .clock:
                        ClockWidgetView(widget: currentWidget)
                    case .calendar:
                        CalendarWidgetView()
                    case .quickNote:
                        QuickNoteWidgetView(widgetID: currentWidget.id, initialText: currentWidget.noteContent, colorHex: currentWidget.noteColorHex)
                            .environmentObject(appState)
                    case .systemGlance:
                        SystemMonitorWidgetView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(
                VisualEffectBlur(material: .hudWindow)
                    .overlay(Color.black.opacity(0.4))
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 3)
        }
    }
}

// MARK: - Clock Widget

public struct ClockWidgetView: View {
    let widget: DesktopWidget
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentTime)
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            Text(timeString)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(dateString)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(14)
        .onReceive(timer) { input in
            currentTime = input
        }
    }
}

// MARK: - Mini Calendar Widget

public struct CalendarWidgetView: View {
    private let calendar = Calendar.current
    private let today = Date()
    
    public var body: some View {
        VStack(spacing: 6) {
            let monthYear = today.formatted(.dateTime.month(.wide).year())
            Text(monthYear)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 16)
                }
            }
            
            // Current day highlight
            let dayNumber = calendar.component(.day, from: today)
            Text("Today: \(dayNumber)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cyan)
        }
        .padding(10)
    }
}

// MARK: - Quick Note Widget

public struct QuickNoteWidgetView: View {
    @EnvironmentObject var appState: AppState
    let widgetID: UUID
    @State var text: String
    let colorHex: String
    
    public init(widgetID: UUID, initialText: String, colorHex: String) {
        self.widgetID = widgetID
        self._text = State(initialValue: initialText)
        self.colorHex = colorHex
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            TextEditor(text: $text)
                .font(.system(size: 12, design: .default))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .foregroundColor(Color(hex: "#1A1A1A"))
                .padding(8)
                .onChange(of: text) { newText in
                    if let idx = appState.widgets.firstIndex(where: { $0.id == widgetID }) {
                        appState.widgets[idx].noteContent = newText
                    }
                }
        }
        .background(Color(hex: colorHex))
        .cornerRadius(8)
        .padding(8)
    }
}

// MARK: - System Monitor Widget

public struct SystemMonitorWidgetView: View {
    @State private var cpuPercent: Int = 18
    @State private var memoryPercent: Int = 42
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CPU Load")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(cpuPercent)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
            }
            ProgressView(value: Double(cpuPercent), total: 100)
                .accentColor(.green)
            
            HStack {
                Text("Memory")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(memoryPercent)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
            }
            ProgressView(value: Double(memoryPercent), total: 100)
                .accentColor(.cyan)
        }
        .padding(14)
    }
}
