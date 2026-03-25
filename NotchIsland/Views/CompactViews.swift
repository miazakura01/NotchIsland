import SwiftUI

// MARK: - Compact Now Playing

struct CompactNowPlayingView: View {
    @ObservedObject var vm: NowPlayingViewModel

    var body: some View {
        HStack(spacing: 8) {
            // アルバムアート
            if let art = vm.info.albumArt {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }

            // 曲名（マーキー風にスクロールできるよう一行で表示）
            Text(vm.info.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer(minLength: 4)

            // 再生/一時停止ボタン
            Button(action: { vm.togglePlayPause() }) {
                Image(systemName: vm.info.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Compact Timer

struct CompactTimerView: View {
    @ObservedObject var vm: TimerViewModel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: vm.state.mode == .timer ? "timer" : "stopwatch")
                .font(.system(size: 12))
                .foregroundColor(.orange)

            Text(vm.state.displayTime)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Compact Calendar

struct CompactCalendarView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11))
                .foregroundColor(.cyan)

            Text(event.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(event.timeString)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Compact Status (Battery + Weather + CPU)

struct CompactStatusView: View {
    @ObservedObject var systemVM: SystemMonitorViewModel
    @ObservedObject var weatherVM: WeatherViewModel

    var body: some View {
        HStack(spacing: 0) {
            // 左: バッテリー
            HStack(spacing: 3) {
                Image(systemName: systemVM.stats.batteryIcon)
                    .font(.system(size: 12))
                    .foregroundColor(systemVM.stats.isCharging ? .green : batteryColor)

                Text("\(systemVM.stats.batteryLevel)%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(systemVM.stats.isCharging ? .green : .white)
                    .fixedSize()
            }

            Spacer(minLength: 4)

            // 中央: 天気
            if weatherVM.hasContent {
                HStack(spacing: 3) {
                    Image(systemName: weatherVM.weather.symbolName)
                        .font(.system(size: 11))
                        .symbolRenderingMode(.multicolor)
                        .frame(width: 14, height: 14)

                    Text(weatherVM.weather.temperatureString)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .fixedSize()
                }
            }

            Spacer(minLength: 4)

            // 右: CPU
            HStack(spacing: 3) {
                Image(systemName: "cpu")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))

                Text(String(format: "%.0f%%", systemVM.stats.cpuUsage))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize()
            }
        }
    }

    private var batteryColor: Color {
        if systemVM.stats.batteryLevel <= 10 { return .red }
        if systemVM.stats.batteryLevel <= 20 { return .orange }
        return .white
    }
}

// MARK: - Compact System Stats (legacy)

struct CompactSystemStatsView: View {
    @ObservedObject var vm: SystemMonitorViewModel

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                Image(systemName: vm.stats.batteryIcon)
                    .font(.system(size: 12))
                    .foregroundColor(vm.stats.isCharging ? .green : batteryColor)

                Text("\(vm.stats.batteryLevel)%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }

            Spacer(minLength: 4)

            HStack(spacing: 3) {
                Image(systemName: "cpu")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))

                Text(String(format: "%.0f%%", vm.stats.cpuUsage))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }

    private var batteryColor: Color {
        if vm.stats.batteryLevel <= 10 { return .red }
        if vm.stats.batteryLevel <= 20 { return .orange }
        return .white
    }
}
