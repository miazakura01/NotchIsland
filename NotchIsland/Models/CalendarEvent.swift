import Foundation

struct CalendarEvent: Identifiable {
    let id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var isAllDay: Bool
    var calendarColor: String?

    var timeString: String {
        if isAllDay { return L("calendar.allDay") }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startDate)
    }

    var isUpcoming: Bool {
        startDate > Date()
    }

    var minutesUntilStart: Int {
        Int(startDate.timeIntervalSinceNow / 60)
    }

    var isImminentSoon: Bool {
        let minutes = minutesUntilStart
        return minutes > 0 && minutes <= 15
    }
}
