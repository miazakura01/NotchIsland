import AppKit
import SwiftUI
import Combine

enum IslandDisplayMode {
    case notchIntegrated  // ノッチ付きディスプレイ
    case floatingPill     // ノッチなし（常時表示）
    case deck             // Deckモード（ノッチなし、ホバーで出現）
}

enum IslandState {
    case compact
    case expanded
    case hidden  // Deckモードで非表示
}

// キーウィンドウになれるNSPanel（ボタンクリックを受け取るために必要）
class ClickablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

class OverlayWindowManager: ObservableObject {
    private var panel: NSPanel?
    private var mouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var screenObserver: Any?

    @Published var state: IslandState = .compact
    @Published var displayMode: IslandDisplayMode = .notchIntegrated
    @Published var isHovering = false
    @Published var expandedHeight: CGFloat = 200

    private let nowPlayingVM: NowPlayingViewModel
    private let timerVM: TimerViewModel
    private let notificationVM: NotificationViewModel
    private let systemMonitorVM: SystemMonitorViewModel
    private let calendarVM: CalendarViewModel
    private let weatherVM: WeatherViewModel
    private let settingsManager: SettingsManager

    private var hideTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var notchInfo: NotchInfo

    init(
        nowPlayingVM: NowPlayingViewModel,
        timerVM: TimerViewModel,
        notificationVM: NotificationViewModel,
        systemMonitorVM: SystemMonitorViewModel,
        calendarVM: CalendarViewModel,
        weatherVM: WeatherViewModel,
        settingsManager: SettingsManager
    ) {
        self.nowPlayingVM = nowPlayingVM
        self.timerVM = timerVM
        self.notificationVM = notificationVM
        self.systemMonitorVM = systemMonitorVM
        self.calendarVM = calendarVM
        self.weatherVM = weatherVM
        self.settingsManager = settingsManager
        self.notchInfo = NotchDetector.detect()
        self.displayMode = resolveDisplayMode()

        observeScreenChanges()
        observeSettings()
    }

    private func resolveDisplayMode() -> IslandDisplayMode {
        if notchInfo.hasNotch {
            return .notchIntegrated
        } else if settingsManager.alwaysVisible && settingsManager.deckModeEnabled {
            // 常に表示 + Deck: 常に表示しつつホバーで展開
            return .floatingPill
        } else if settingsManager.alwaysVisible {
            return .floatingPill
        } else if settingsManager.deckModeEnabled {
            return .deck
        } else {
            // 両方OFF: フローティングピルで常時表示（最低限の表示）
            return .floatingPill
        }
    }

    // MARK: - Show Overlay

    func showOverlay() {
        notchInfo = NotchDetector.detect()
        displayMode = resolveDisplayMode()

        let contentView = IslandContainerView(
            windowManager: self,
            nowPlayingVM: nowPlayingVM,
            timerVM: timerVM,
            notificationVM: notificationVM,
            systemMonitorVM: systemMonitorVM,
            calendarVM: calendarVM,
            weatherVM: weatherVM,
            settingsManager: settingsManager
        )

        let hostingView = NSHostingView(rootView: contentView)

        let initialFrame = calculateFrame(for: displayMode == .deck ? .hidden : .compact)

        let panel = ClickablePanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.acceptsMouseMovedEvents = true
        panel.becomesKeyOnlyIfNeeded = true

        panel.level = .statusBar + 1
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.contentView = hostingView
        panel.ignoresMouseEvents = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow

        self.panel = panel

        if displayMode == .deck {
            state = .hidden
            panel.alphaValue = 0
        } else {
            state = .compact
            panel.alphaValue = 1
        }

        panel.orderFrontRegardless()
        setupMouseTracking()
    }

    // MARK: - Frame Calculation

    func calculateFrame(for state: IslandState) -> CGRect {
        let screen = notchInfo.screen
        let screenFrame = screen.frame

        switch state {
        case .compact:
            if notchInfo.hasNotch {
                let notch = notchInfo.notchRect
                return CGRect(
                    x: notch.origin.x - 10,
                    y: notch.origin.y - 4,
                    width: notch.width + 20,
                    height: notch.height + 8
                )
            } else {
                let width: CGFloat = 200
                let height: CGFloat = 36
                return CGRect(
                    x: screenFrame.midX - width / 2,
                    y: screenFrame.maxY - screen.safeAreaTop - height - 4,
                    width: width,
                    height: height
                )
            }

        case .expanded:
            let width: CGFloat = 400
            let height: CGFloat = max(expandedHeight, 200)
            let topY: CGFloat
            if notchInfo.hasNotch {
                topY = notchInfo.notchRect.origin.y - 4
            } else {
                topY = screenFrame.maxY - screen.safeAreaTop - 4
            }
            return CGRect(
                x: screenFrame.midX - width / 2,
                y: topY - height,
                width: width,
                height: height
            )

        case .hidden:
            let width: CGFloat = 200
            let height: CGFloat = 36
            return CGRect(
                x: screenFrame.midX - width / 2,
                y: screenFrame.maxY,
                width: width,
                height: height
            )
        }
    }

    // MARK: - State Management

    func toggleExpanded() {
        switch state {
        case .compact:
            state = .expanded
            updatePanelFrameAnimated()
        case .expanded:
            state = .compact
            updatePanelFrameAnimated()
        case .hidden:
            revealIsland()
        }
    }

    func expandIsland() {
        guard state != .expanded else { return }
        state = .expanded
        updatePanelFrameAnimated()
    }

    func collapseIsland() {
        guard state == .expanded else { return }
        state = .compact
        updatePanelFrameAnimated()
    }

    private func revealIsland() {
        guard state == .hidden else { return }
        state = .compact
        let newFrame = calculateFrame(for: .compact)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = true
            panel?.animator().setFrame(newFrame, display: true)
            panel?.animator().alphaValue = 1
        }
    }

    private func hideIsland() {
        guard displayMode == .deck, state == .compact else { return }
        let newFrame = calculateFrame(for: .hidden)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            context.allowsImplicitAnimation = true
            self.panel?.animator().setFrame(newFrame, display: true)
            self.panel?.animator().alphaValue = 0
        }, completionHandler: {
            self.state = .hidden
        })
    }

    private func shrinkToFit() {
        guard state == .expanded, let panel = panel, let hostingView = panel.contentView else { return }

        let screen = notchInfo.screen
        let screenFrame = screen.frame
        let width: CGFloat = 400

        // fittingSizeでコンテンツに合わせた高さを取得
        let fitting = hostingView.fittingSize.height
        let height = max(min(fitting + 10, 400), 180)

        let topY: CGFloat
        if notchInfo.hasNotch {
            topY = notchInfo.notchRect.origin.y - 4
        } else {
            topY = screenFrame.maxY - screen.safeAreaTop - 4
        }

        let newFrame = CGRect(
            x: screenFrame.midX - width / 2,
            y: topY - height,
            width: width,
            height: height
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(newFrame, display: true)
        }
    }

    func updatePanelFrameAnimated() {
        guard let panel = panel else { return }
        let newFrame = calculateFrame(for: state)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(newFrame, display: true)
        }

        // コンテンツ再描画を強制
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            panel.contentView?.needsLayout = true
            panel.contentView?.needsDisplay = true
            panel.displayIfNeeded()
        }
    }

    // MARK: - Mouse Tracking

    private func setupMouseTracking() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
            if event.type == .mouseMoved {
                self?.handleMouseMoved(event)
            } else if event.type == .leftMouseDown {
                // 外側クリックで閉じる
                self?.handleOutsideClick()
            }
        }

        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }
    }

    private func handleMouseMoved(_ event: NSEvent) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = notchInfo.screen
        let screenFrame = screen.frame

        // Deckモード: 画面上部中央へのホバーで出現
        if displayMode == .deck && state == .hidden {
            let triggerWidth = screenFrame.width * 0.35
            let triggerRect = CGRect(
                x: screenFrame.midX - triggerWidth / 2,
                y: screenFrame.maxY - 5,
                width: triggerWidth,
                height: 5
            )

            if triggerRect.contains(mouseLocation) {
                revealIsland()
                return
            }
        }

        // ホバー状態の更新
        if let panelFrame = panel?.frame {
            let expandedFrame = panelFrame.insetBy(dx: -20, dy: -20)
            let isInside = expandedFrame.contains(mouseLocation)

            if isInside != isHovering {
                isHovering = isInside

                if isInside {
                    hideTimer?.invalidate()
                    hideTimer = nil
                    // ホバーで展開
                    if settingsManager.expandOnHover && state == .compact {
                        expandIsland()
                    }
                } else {
                    // ホバーで展開してた場合は閉じる
                    if settingsManager.expandOnHover && state == .expanded {
                        collapseIsland()
                    }
                    // Deckのみ（常時表示OFF）: カーソル離れたら隠す
                    if displayMode == .deck && state == .compact && !settingsManager.alwaysVisible {
                        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                            self?.hideIsland()
                        }
                    }
                }
            }
        }
    }

    private func handleOutsideClick() {
        guard state == .expanded else { return }
        let mouseLocation = NSEvent.mouseLocation
        if let panelFrame = panel?.frame, !panelFrame.contains(mouseLocation) {
            collapseIsland()
        }
    }

    // MARK: - Screen Changes

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }
    }

    private var settingsObserver: Any?

    private func observeSettings() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] (_: Notification) in
            self?.handleDisplayModeChange()
        }
    }

    private func handleDisplayModeChange() {
        let newMode = resolveDisplayMode()
        guard newMode != displayMode else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.panel?.animator().alphaValue = 0
        }, completionHandler: {
            self.displayMode = newMode
            if newMode == .deck {
                self.state = .hidden
            } else {
                self.state = .compact
            }
            self.updatePanelFrameAnimated()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                self.panel?.animator().alphaValue = newMode == .deck ? 0 : 1
            }
        })
    }

    private func handleScreenChange() {
        let oldMode = displayMode
        notchInfo = NotchDetector.detect()
        displayMode = resolveDisplayMode()

        if oldMode != displayMode {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                self.panel?.animator().alphaValue = 0
            }, completionHandler: {
                self.state = self.displayMode == .deck ? .hidden : .compact
                self.updatePanelFrameAnimated()
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    self.panel?.animator().alphaValue = self.displayMode == .deck ? 0 : 1
                }
            })
        } else {
            updatePanelFrameAnimated()
        }
    }

    deinit {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = settingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        hideTimer?.invalidate()
    }
}
