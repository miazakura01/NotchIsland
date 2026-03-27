import Foundation
import UserNotifications

class TimerViewModel: ObservableObject {
    @Published var state = TimerState()
    @Published var hasActiveTimer = false

    private var timer: Timer?
    private var timerStartDate: Date?
    private var timerStartRemaining: TimeInterval = 0
    private var stopwatchStartDate: Date?
    private var stopwatchAccumulated: TimeInterval = 0

    // MARK: - Timer

    func setTimerDuration(minutes: Int, seconds: Int = 0) {
        let duration = TimeInterval(minutes * 60 + seconds)
        state.timerDuration = duration
        state.timerRemaining = duration
    }

    func startTimer() {
        state.mode = .timer
        state.isRunning = true
        hasActiveTimer = true

        timerStartDate = Date()
        timerStartRemaining = state.timerRemaining

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startDate = self.timerStartDate else { return }
            let elapsed = Date().timeIntervalSince(startDate)
            let remaining = self.timerStartRemaining - elapsed

            if remaining > 0 {
                self.state.timerRemaining = remaining
            } else {
                self.state.timerRemaining = 0
                self.timerFinished()
            }
        }
    }

    private func timerFinished() {
        stopTimer()
        sendNotification(title: L("timer.finished.title"), body: L("timer.finished.body"))
    }

    // MARK: - Stopwatch

    func startStopwatch() {
        state.mode = .stopwatch
        state.isRunning = true
        hasActiveTimer = true

        stopwatchStartDate = Date()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startDate = self.stopwatchStartDate else { return }
            self.state.stopwatchElapsed = self.stopwatchAccumulated + Date().timeIntervalSince(startDate)
        }
    }

    func addLap() {
        guard state.mode == .stopwatch, state.isRunning else { return }
        state.laps.append(state.stopwatchElapsed)
    }

    // MARK: - Common

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        state.isRunning = false

        // ストップウォッチの累積時間を保存
        if state.mode == .stopwatch {
            stopwatchAccumulated = state.stopwatchElapsed
            stopwatchStartDate = nil
        }
        timerStartDate = nil
    }

    func resetTimer() {
        stopTimer()
        hasActiveTimer = false
        switch state.mode {
        case .timer:
            state.timerRemaining = state.timerDuration
            timerStartRemaining = 0
        case .stopwatch:
            state.stopwatchElapsed = 0
            stopwatchAccumulated = 0
            state.laps.removeAll()
        }
    }

    func toggleRunning() {
        if state.isRunning {
            stopTimer()
        } else {
            switch state.mode {
            case .timer:
                startTimer()
            case .stopwatch:
                startStopwatch()
            }
        }
    }

    // MARK: - Notification

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    deinit {
        timer?.invalidate()
    }
}
