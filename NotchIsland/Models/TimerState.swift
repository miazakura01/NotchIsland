import Foundation

enum TimerMode {
    case timer
    case stopwatch
}

struct TimerState {
    var mode: TimerMode = .timer
    var isRunning: Bool = false

    // Timer
    var timerDuration: TimeInterval = 300  // デフォルト5分
    var timerRemaining: TimeInterval = 300

    // Stopwatch
    var stopwatchElapsed: TimeInterval = 0
    var laps: [TimeInterval] = []

    var displayTime: String {
        let time: TimeInterval
        switch mode {
        case .timer:
            time = timerRemaining
        case .stopwatch:
            time = stopwatchElapsed
        }

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let fraction = Int((time.truncatingRemainder(dividingBy: 1)) * 10)

        if time >= 3600 {
            let hours = Int(time) / 3600
            let mins = (Int(time) % 3600) / 60
            return String(format: "%d:%02d:%02d", hours, mins, seconds)
        }
        return String(format: "%d:%02d.%d", minutes, seconds, fraction)
    }

    var timerProgress: Double {
        guard timerDuration > 0 else { return 0 }
        return 1.0 - (timerRemaining / timerDuration)
    }
}
