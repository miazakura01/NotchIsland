import SwiftUI

struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

enum IslandTab: CaseIterable {
    case nowPlaying
    case timer
    case weather
    case systemStats
    case calendar

    var label: String {
        switch self {
        case .nowPlaying: return L("tab.nowPlaying")
        case .timer: return L("tab.timer")
        case .weather: return L("tab.weather")
        case .systemStats: return L("tab.systemStats")
        case .calendar: return L("tab.calendar")
        }
    }
}

struct IslandContainerView: View {
    @ObservedObject var windowManager: OverlayWindowManager
    @ObservedObject var nowPlayingVM: NowPlayingViewModel
    @ObservedObject var timerVM: TimerViewModel
    @ObservedObject var notificationVM: NotificationViewModel
    @ObservedObject var systemMonitorVM: SystemMonitorViewModel
    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var weatherVM: WeatherViewModel
    @ObservedObject var settingsManager: SettingsManager

    @State private var currentTab: IslandTab = .nowPlaying
    @State private var isHovering = false
    @State private var contentHeight: CGFloat = 36

    var body: some View {
        Group {
            if notificationVM.hasNotification {
                notificationOverlay
            } else {
                switch windowManager.state {
                case .compact:
                    compactContent
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentTab = .nowPlaying
                            windowManager.toggleExpanded()
                        }
                case .expanded:
                    expandedContent
                case .hidden:
                    EmptyView()
                }
            }
        }
        .background(glassBackground)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(ContentHeightKey.self) { height in
            if height != contentHeight && height > 0 {
                contentHeight = height
                windowManager.expandedHeight = height
                if windowManager.state == .expanded {
                    windowManager.updatePanelFrameAnimated()
                }
            }
        }
        .scaleEffect(isHovering && windowManager.state == .compact ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: windowManager.state)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    // MARK: - Compact

    private var compactContent: some View {
        HStack(spacing: 8) {
            if nowPlayingVM.hasContent {
                CompactNowPlayingView(vm: nowPlayingVM)
            } else if timerVM.hasActiveTimer {
                CompactTimerView(vm: timerVM)
            } else if let event = calendarVM.nextEvent, event.isImminentSoon {
                CompactCalendarView(event: event)
            } else {
                CompactStatusView(systemVM: systemMonitorVM, weatherVM: weatherVM)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - Expanded

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // タブバー + 閉じる & 設定ボタン
            HStack(spacing: 0) {
                ForEach(IslandTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }

                Spacer()

                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 12)

            // タブコンテンツ
            Group {
                switch currentTab {
                case .nowPlaying:
                    NowPlayingView(vm: nowPlayingVM)
                case .timer:
                    TimerView(vm: timerVM)
                case .weather:
                    WeatherView(vm: weatherVM)
                case .systemStats:
                    SystemStatsView(vm: systemMonitorVM)
                case .calendar:
                    CalendarView(vm: calendarVM)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: currentTab)
            .padding(12)
        }
    }

    private func tabButton(_ tab: IslandTab) -> some View {
        Button(action: {
            currentTab = tab
        }) {
            Text(tab.label)
                .font(.system(size: 11, weight: currentTab == tab ? .semibold : .regular))
                .foregroundColor(currentTab == tab ? .white : .gray)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    currentTab == tab ?
                    RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.12)).overlay(
                        RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    ) :
                    nil
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.thinMaterial)
                .opacity(0.7)

            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.0
                )
        }
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }

    // MARK: - Notification Overlay

    private var notificationOverlay: some View {
        NotificationView(vm: notificationVM)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .opacity
            ))
    }
}
