import Foundation
import UserNotifications
import Combine

class TimerViewModel: ObservableObject {
    @Published var state = TimerState()
    @Published var hasActiveTimer = false

    private var timer: Timer?

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

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.state.timerRemaining > 0 {
                self.state.timerRemaining -= 0.1
            } else {
                self.state.timerRemaining = 0
                self.timerFinished()
            }
        }
    }

    private func timerFinished() {
        stopTimer()
        sendNotification(title: "タイマー完了", body: "設定した時間が経過しました")
    }

    // MARK: - Stopwatch

    func startStopwatch() {
        state.mode = .stopwatch
        state.isRunning = true
        hasActiveTimer = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.state.stopwatchElapsed += 0.1
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
    }

    func resetTimer() {
        stopTimer()
        hasActiveTimer = false
        switch state.mode {
        case .timer:
            state.timerRemaining = state.timerDuration
        case .stopwatch:
            state.stopwatchElapsed = 0
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
