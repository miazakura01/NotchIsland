import SwiftUI

struct TimerView: View {
    @ObservedObject var vm: TimerViewModel

    @State private var selectedMinutes = 5
    @State private var selectedSeconds = 0

    var body: some View {
        VStack(spacing: 12) {
            // モード切替
            HStack(spacing: 0) {
                modeButton("タイマー", mode: .timer)
                modeButton("ストップウォッチ", mode: .stopwatch)
            }
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            switch vm.state.mode {
            case .timer:
                timerContent
            case .stopwatch:
                stopwatchContent
            }
        }
    }

    // MARK: - Timer

    private var timerContent: some View {
        VStack(spacing: 10) {
            if !vm.hasActiveTimer {
                // 時間設定
                HStack(spacing: 4) {
                    Picker("", selection: $selectedMinutes) {
                        ForEach(0..<60) { Text("\($0)分").tag($0) }
                    }
                    .frame(width: 70)
                    .labelsHidden()

                    Picker("", selection: $selectedSeconds) {
                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) {
                            Text("\($0)秒").tag($0)
                        }
                    }
                    .frame(width: 70)
                    .labelsHidden()
                }
                .colorScheme(.dark)
            }

            // 表示
            Text(vm.state.displayTime)
                .font(.system(size: 32, weight: .light, design: .monospaced))
                .foregroundColor(.white)

            // プログレス
            if vm.hasActiveTimer {
                ProgressView(value: vm.state.timerProgress)
                    .tint(.orange)
                    .scaleEffect(y: 2)
            }

            // ボタン
            HStack(spacing: 20) {
                if vm.hasActiveTimer {
                    controlButton(
                        vm.state.isRunning ? "pause.fill" : "play.fill",
                        color: .orange
                    ) {
                        vm.toggleRunning()
                    }

                    controlButton("xmark", color: .red) {
                        vm.resetTimer()
                    }
                } else {
                    controlButton("play.fill", color: .green) {
                        vm.setTimerDuration(minutes: selectedMinutes, seconds: selectedSeconds)
                        vm.startTimer()
                    }
                }
            }
        }
    }

    // MARK: - Stopwatch

    private var stopwatchContent: some View {
        VStack(spacing: 10) {
            Text(vm.state.displayTime)
                .font(.system(size: 32, weight: .light, design: .monospaced))
                .foregroundColor(.white)

            HStack(spacing: 20) {
                if vm.state.isRunning {
                    controlButton("flag.fill", color: .blue) {
                        vm.addLap()
                    }
                }

                controlButton(
                    vm.state.isRunning ? "pause.fill" : "play.fill",
                    color: vm.state.isRunning ? .orange : .green
                ) {
                    if !vm.hasActiveTimer {
                        vm.state.mode = .stopwatch
                        vm.hasActiveTimer = true
                    }
                    vm.toggleRunning()
                }

                if vm.hasActiveTimer && !vm.state.isRunning {
                    controlButton("arrow.counterclockwise", color: .red) {
                        vm.resetTimer()
                    }
                }
            }

            // ラップタイム
            if !vm.state.laps.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(vm.state.laps.indices.reversed(), id: \.self) { i in
                            HStack {
                                Text("ラップ \(i + 1)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(formatLapTime(vm.state.laps[i]))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(maxHeight: 40)
            }
        }
    }

    // MARK: - Helpers

    private func modeButton(_ title: String, mode: TimerMode) -> some View {
        Button(action: {
            if !vm.hasActiveTimer {
                vm.state.mode = mode
            }
        }) {
            Text(title)
                .font(.system(size: 11, weight: vm.state.mode == mode ? .semibold : .regular))
                .foregroundColor(vm.state.mode == mode ? .white : .gray)
                .padding(.vertical, 5)
                .padding(.horizontal, 12)
                .background(
                    vm.state.mode == mode ?
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.2)) : nil
                )
        }
        .buttonStyle(.plain)
    }

    private func controlButton(_ symbol: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color))
        }
        .buttonStyle(.plain)
    }

    private func formatLapTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let fraction = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", minutes, seconds, fraction)
    }
}
