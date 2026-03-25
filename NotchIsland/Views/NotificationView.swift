import SwiftUI

struct NotificationView: View {
    @ObservedObject var vm: NotificationViewModel

    var body: some View {
        if let notification = vm.currentNotification {
            HStack(spacing: 10) {
                // アプリアイコン
                if let icon = notification.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 28, height: 28)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.appName)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)

                    Text(notification.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if !notification.body.isEmpty {
                        Text(notification.body)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .onTapGesture {
                vm.dismissCurrentNotification()
            }
        }
    }
}
