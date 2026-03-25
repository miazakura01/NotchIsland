import AppKit
import Carbon

enum TilePosition: String, CaseIterable {
    case left       // 左半分
    case right      // 右半分
    case topLeft    // 左上1/4
    case topRight   // 右上1/4
    case bottomLeft // 左下1/4
    case bottomRight// 右下1/4
    case maximize   // 最大化
    case top        // 上半分
    case bottom     // 下半分
    case center     // 中央

    var label: String {
        switch self {
        case .left: return "左半分"
        case .right: return "右半分"
        case .topLeft: return "左上"
        case .topRight: return "右上"
        case .bottomLeft: return "左下"
        case .bottomRight: return "右下"
        case .maximize: return "最大化"
        case .top: return "上半分"
        case .bottom: return "下半分"
        case .center: return "中央"
        }
    }

    var icon: String {
        switch self {
        case .left: return "rectangle.lefthalf.filled"
        case .right: return "rectangle.righthalf.filled"
        case .topLeft: return "rectangle.inset.topleft.filled"
        case .topRight: return "rectangle.inset.topright.filled"
        case .bottomLeft: return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        case .maximize: return "rectangle.fill"
        case .top: return "rectangle.tophalf.filled"
        case .bottom: return "rectangle.bottomhalf.filled"
        case .center: return "rectangle.center.inset.filled"
        }
    }
}

class WindowTilingService {
    static let shared = WindowTilingService()

    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var isAccessibilityGranted = false

    // MARK: - Accessibility Check

    func requestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)
        return isAccessibilityGranted
    }

    func checkAccessibility() -> Bool {
        isAccessibilityGranted = AXIsProcessTrusted()
        return isAccessibilityGranted
    }

    // MARK: - Tile Window

    func tileActiveWindow(to position: TilePosition) {
        guard checkAccessibility() else {
            print("[Tiling] Accessibility not granted")
            _ = requestAccessibility()
            return
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        var windowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue) == .success,
              let window = windowValue else {
            print("[Tiling] No focused window")
            return
        }

        // CFTypeRef -> AXUIElement 安全キャスト
        let windowElement = window as! AXUIElement  // AXUIElementCopyAttributeValueが成功した場合、kAXFocusedWindowAttributeは常にAXUIElement
        let frame = calculateFrame(for: position)

        setWindowPosition(windowElement, point: frame.origin)
        setWindowSize(windowElement, size: frame.size)
    }

    // MARK: - Frame Calculation

    private func calculateFrame(for position: TilePosition) -> CGRect {
        guard let screen = NSScreen.main else { return .zero }

        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.origin.x
        let w = visibleFrame.width
        let h = visibleFrame.height

        // macOSの座標系: 左下が原点 → AXは左上が原点に変換
        let screenHeight = screen.frame.height
        let menuBarHeight = screenHeight - visibleFrame.height - visibleFrame.origin.y

        switch position {
        case .left:
            return CGRect(x: x, y: menuBarHeight, width: w / 2, height: h)
        case .right:
            return CGRect(x: x + w / 2, y: menuBarHeight, width: w / 2, height: h)
        case .top:
            return CGRect(x: x, y: menuBarHeight, width: w, height: h / 2)
        case .bottom:
            return CGRect(x: x, y: menuBarHeight + h / 2, width: w, height: h / 2)
        case .topLeft:
            return CGRect(x: x, y: menuBarHeight, width: w / 2, height: h / 2)
        case .topRight:
            return CGRect(x: x + w / 2, y: menuBarHeight, width: w / 2, height: h / 2)
        case .bottomLeft:
            return CGRect(x: x, y: menuBarHeight + h / 2, width: w / 2, height: h / 2)
        case .bottomRight:
            return CGRect(x: x + w / 2, y: menuBarHeight + h / 2, width: w / 2, height: h / 2)
        case .maximize:
            return CGRect(x: x, y: menuBarHeight, width: w, height: h)
        case .center:
            let cw = w * 0.6
            let ch = h * 0.7
            return CGRect(x: x + (w - cw) / 2, y: menuBarHeight + (h - ch) / 2, width: cw, height: ch)
        }
    }

    // MARK: - AXUIElement Helpers

    private func setWindowPosition(_ window: AXUIElement, point: CGPoint) {
        var pos = point
        if let value = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
        }
    }

    private func setWindowSize(_ window: AXUIElement, size: CGSize) {
        var sz = size
        if let value = AXValueCreate(.cgSize, &sz) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
        }
    }

    // MARK: - Global Hotkeys

    func registerHotkeys() {
        // Ctrl+Option + 矢印キー
        registerHotkey(keyCode: 123, modifiers: controlKey | optionKey, id: 0) // ← 左
        registerHotkey(keyCode: 124, modifiers: controlKey | optionKey, id: 1) // → 右
        registerHotkey(keyCode: 126, modifiers: controlKey | optionKey, id: 2) // ↑ 上/最大化
        registerHotkey(keyCode: 125, modifiers: controlKey | optionKey, id: 3) // ↓ 下/中央

        // Ctrl+Option+Shift + 矢印キー で4分割
        registerHotkey(keyCode: 123, modifiers: controlKey | optionKey | shiftKey, id: 4) // 左上
        registerHotkey(keyCode: 124, modifiers: controlKey | optionKey | shiftKey, id: 5) // 右上
        registerHotkey(keyCode: 125, modifiers: controlKey | optionKey | shiftKey, id: 6) // 左下
        registerHotkey(keyCode: 126, modifiers: controlKey | optionKey | shiftKey, id: 7) // 右下

        // Ctrl+Option+Return で最大化
        registerHotkey(keyCode: 36, modifiers: controlKey | optionKey, id: 8)

        // Ctrl+Option+C で中央
        registerHotkey(keyCode: 8, modifiers: controlKey | optionKey, id: 9)

        installEventHandler()
    }

    private func registerHotkey(keyCode: UInt32, modifiers: Int, id: UInt32) {
        var hotKeyID = EventHotKeyID(signature: OSType(0x4E49), id: id) // "NI"
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            UInt32(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            hotKeyRefs.append(hotKeyRef)
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

                let service = WindowTilingService.shared
                switch hotKeyID.id {
                case 0: service.tileActiveWindow(to: .left)
                case 1: service.tileActiveWindow(to: .right)
                case 2: service.tileActiveWindow(to: .maximize)
                case 3: service.tileActiveWindow(to: .center)
                case 4: service.tileActiveWindow(to: .topLeft)
                case 5: service.tileActiveWindow(to: .topRight)
                case 6: service.tileActiveWindow(to: .bottomLeft)
                case 7: service.tileActiveWindow(to: .bottomRight)
                case 8: service.tileActiveWindow(to: .maximize)
                case 9: service.tileActiveWindow(to: .center)
                default: break
                }

                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }

    // MARK: - Edge Trigger (マウスドラッグ検知)

    private var edgeMonitor: Any?

    func startEdgeDetection() {
        edgeMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            if event.type == .leftMouseDragged {
                self?.handleDrag(event)
            } else if event.type == .leftMouseUp {
                self?.handleDragEnd(event)
            }
        }
    }

    private var pendingTile: TilePosition?

    private func handleDrag(_ event: NSEvent) {
        guard let screen = NSScreen.main else { return }
        let loc = NSEvent.mouseLocation
        let frame = screen.frame
        let threshold: CGFloat = 5

        if loc.x <= frame.minX + threshold {
            pendingTile = loc.y > frame.midY ? .topLeft : .bottomLeft
            if abs(loc.y - frame.midY) < frame.height * 0.3 {
                pendingTile = .left
            }
        } else if loc.x >= frame.maxX - threshold {
            pendingTile = loc.y > frame.midY ? .topRight : .bottomRight
            if abs(loc.y - frame.midY) < frame.height * 0.3 {
                pendingTile = .right
            }
        } else if loc.y >= frame.maxY - threshold {
            pendingTile = .maximize
        } else {
            pendingTile = nil
        }
    }

    private func handleDragEnd(_ event: NSEvent) {
        if let tile = pendingTile {
            // 少し遅延してウィンドウ配置（ドロップ後に対象ウィンドウがフォーカスされるのを待つ）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.tileActiveWindow(to: tile)
            }
            pendingTile = nil
        }
    }

    func stopEdgeDetection() {
        if let monitor = edgeMonitor {
            NSEvent.removeMonitor(monitor)
            edgeMonitor = nil
        }
    }

    func unregisterHotkeys() {
        for ref in hotKeyRefs {
            if let ref = ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
    }

    deinit {
        unregisterHotkeys()
        stopEdgeDetection()
    }
}
