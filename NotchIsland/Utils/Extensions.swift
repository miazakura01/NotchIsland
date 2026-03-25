import AppKit
import SwiftUI

extension Color {
    static let islandBackground = Color.black
    static let islandText = Color.white
    static let islandSubtext = Color(white: 0.667) // #AAAAAA
}

extension NSScreen {
    /// メインのビルトインディスプレイを探す
    static var builtInScreen: NSScreen? {
        screens.first { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                return false
            }
            return CGDisplayIsBuiltin(screenNumber) != 0
        }
    }

    /// 外部ディスプレイの一覧
    static var externalScreens: [NSScreen] {
        screens.filter { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                return false
            }
            return CGDisplayIsBuiltin(screenNumber) == 0
        }
    }
}

extension View {
    func islandShadow() -> some View {
        self.shadow(color: .black.opacity(0.5), radius: 10, y: 5)
    }
}
