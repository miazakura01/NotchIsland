import SwiftUI

struct CalendarView: View {
    @ObservedObject var vm: CalendarViewModel

    var body: some View {
        if vm.hasAccess {
            if vm.upcomingEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.3))

                    Text("\(L("calendar.noEvents"))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(vm.upcomingEvents) { event in
                            eventRow(event)
                        }
                    }
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)

                Text("\(L("calendar.noAccess"))")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Button(L("calendar.openSettings")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: 10) {
            // 時刻インジケーター
            RoundedRectangle(cornerRadius: 2)
                .fill(event.isImminentSoon ? Color.orange : Color.cyan)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(event.timeString)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)

                    if let location = event.location, !location.isEmpty {
                        Text("• \(location)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if event.isImminentSoon {
                Text("\(event.minutesUntilStart)分後")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            event.isImminentSoon ?
            RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)) : nil
        )
    }
}
