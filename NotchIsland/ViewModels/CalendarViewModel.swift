import Foundation
import EventKit
import Combine

class CalendarViewModel: ObservableObject {
    @Published var nextEvent: CalendarEvent?
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var hasAccess = false

    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?
    private var storeObserver: Any?

    func requestAccessAndFetch() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasAccess = granted
                    if granted {
                        self?.fetchEvents()
                        self?.observeChanges()
                    }
                    if let error = error {
                        print("[Calendar] Access error: \(error)")
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasAccess = granted
                    if granted {
                        self?.fetchEvents()
                        self?.observeChanges()
                    }
                }
            }
        }

        // 30秒おきに予定を更新
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.fetchEvents()
        }
    }

    private func observeChanges() {
        storeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            self?.fetchEvents()
        }
    }

    func fetchEvents() {
        guard hasAccess else {
            print("[Calendar] No access")
            return
        }

        // 今日の0時から明日の終わりまで取得（進行中の予定も含む）
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfTomorrow,
            calendars: nil
        )

        let now = Date()
        let events = eventStore.events(matching: predicate)
            .filter { $0.endDate > now } // まだ終わってない予定
            .sorted { $0.startDate < $1.startDate }
            .prefix(5)
            .map { ekEvent -> CalendarEvent in
                CalendarEvent(
                    id: ekEvent.eventIdentifier,
                    title: ekEvent.title ?? L("calendar.noTitle"),
                    startDate: ekEvent.startDate,
                    endDate: ekEvent.endDate,
                    location: ekEvent.location,
                    isAllDay: ekEvent.isAllDay,
                    calendarColor: nil
                )
            }

        self.upcomingEvents = Array(events)
        self.nextEvent = events.first
        print("[Calendar] Fetched \(events.count) events")
    }

    deinit {
        refreshTimer?.invalidate()
        if let observer = storeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
