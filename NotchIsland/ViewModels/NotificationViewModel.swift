import Foundation
import AppKit
import Combine

struct IslandNotification: Identifiable {
    let id = UUID()
    let appName: String
    let appIcon: NSImage?
    let title: String
    let body: String
    let timestamp: Date
}

class NotificationViewModel: ObservableObject {
    @Published var currentNotification: IslandNotification?
    @Published var hasNotification = false

    private var notificationQueue: [IslandNotification] = []
    private var dismissTimer: Timer?
    private var observers: [NSObjectProtocol] = []

    func startMonitoring() {
        // NSDistributedNotificationCenter でシステム通知を監視
        let distributedCenter = DistributedNotificationCenter.default()

        let observer = distributedCenter.addObserver(
            forName: nil,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // UserNotification系の通知をフィルタ
            let name = notification.name.rawValue
            if name.contains("com.apple.notificationcenter") ||
               name.contains("UserNotification") {
                self?.handleSystemNotification(notification)
            }
        }
        observers.append(observer)
    }

    private func handleSystemNotification(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]

        let appName = userInfo["app"] as? String ?? "通知"
        let title = userInfo["title"] as? String ?? notification.name.rawValue
        let body = userInfo["body"] as? String ?? ""

        var appIcon: NSImage? = nil
        if let bundleId = userInfo["bundleIdentifier"] as? String,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            appIcon = NSWorkspace.shared.icon(forFile: appURL.path)
        }

        let islandNotification = IslandNotification(
            appName: appName,
            appIcon: appIcon,
            title: title,
            body: body,
            timestamp: Date()
        )

        enqueueNotification(islandNotification)
    }

    func enqueueNotification(_ notification: IslandNotification) {
        notificationQueue.append(notification)

        if currentNotification == nil {
            showNextNotification()
        }
    }

    private func showNextNotification() {
        guard !notificationQueue.isEmpty else {
            currentNotification = nil
            hasNotification = false
            return
        }

        let notification = notificationQueue.removeFirst()
        currentNotification = notification
        hasNotification = true

        // 4秒後に自動消去
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            self?.dismissCurrentNotification()
        }
    }

    func dismissCurrentNotification() {
        dismissTimer?.invalidate()
        currentNotification = nil
        hasNotification = false

        // 0.5秒後に次の通知を表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showNextNotification()
        }
    }

    func stopMonitoring() {
        observers.forEach { DistributedNotificationCenter.default().removeObserver($0) }
        observers.removeAll()
        dismissTimer?.invalidate()
    }

    deinit {
        stopMonitoring()
    }
}
