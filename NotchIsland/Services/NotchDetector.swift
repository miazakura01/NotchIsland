import AppKit

struct NotchInfo {
    let hasNotch: Bool
    let notchRect: CGRect
    let screen: NSScreen
}

class NotchDetector {
    static func detect(for screen: NSScreen? = nil) -> NotchInfo {
        // NSScreen.screensが空になることは実質ないが安全にfirst
        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first ?? NSScreen.main!

        // macOS 12+ ノッチ付きMacBookの場合、safeAreaInsetsにtopが設定される
        if #available(macOS 12.0, *) {
            let topInset = targetScreen.safeAreaInsets.top
            if topInset > 0 {
                let frame = targetScreen.frame
                // ノッチの推定サイズ
                // ノッチ幅は約180px（14インチ）〜約230px（16インチ）
                let notchWidth: CGFloat = estimateNotchWidth(screenWidth: frame.width)
                let notchHeight: CGFloat = topInset
                let notchX = frame.midX - notchWidth / 2
                let notchY = frame.maxY - notchHeight

                let notchRect = CGRect(
                    x: notchX,
                    y: notchY,
                    width: notchWidth,
                    height: notchHeight
                )

                return NotchInfo(hasNotch: true, notchRect: notchRect, screen: targetScreen)
            }
        }

        // ノッチなし: 画面上部中央にフローティングピル用のデフォルト位置を返す
        let frame = targetScreen.frame
        let defaultWidth: CGFloat = 200
        let defaultHeight: CGFloat = 36
        let pillRect = CGRect(
            x: frame.midX - defaultWidth / 2,
            y: frame.maxY - targetScreen.safeAreaTop - defaultHeight - 4,
            width: defaultWidth,
            height: defaultHeight
        )

        return NotchInfo(hasNotch: false, notchRect: pillRect, screen: targetScreen)
    }

    static func isBuiltInDisplay(_ screen: NSScreen) -> Bool {
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return false
        }
        return CGDisplayIsBuiltin(screenNumber) != 0
    }

    private static func estimateNotchWidth(screenWidth: CGFloat) -> CGFloat {
        // 14インチ MacBook Pro: 画面幅3024px → ノッチ約180px相当
        // 16インチ MacBook Pro: 画面幅3456px → ノッチ約230px相当
        // ポイント単位で大体の比率で推定
        if screenWidth >= 1700 {
            return 230
        } else if screenWidth >= 1500 {
            return 200
        } else {
            return 180
        }
    }
}

extension NSScreen {
    var safeAreaTop: CGFloat {
        if #available(macOS 12.0, *) {
            return safeAreaInsets.top
        }
        return 0
    }
}
