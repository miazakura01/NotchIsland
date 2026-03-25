import SwiftUI

@main
struct NotchIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 空のWindowGroupは不要、AppDelegateで全て管理
        Settings {
            EmptyView()
        }
    }
}
