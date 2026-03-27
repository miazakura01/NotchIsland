import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var overlayWindowManager: OverlayWindowManager!
    let settingsManager = SettingsManager()
    private var settingsWindow: NSWindow?

    // ViewModels
    let nowPlayingVM = NowPlayingViewModel()
    let timerVM = TimerViewModel()
    let notificationVM = NotificationViewModel()
    let systemMonitorVM = SystemMonitorViewModel()
    let calendarVM = CalendarViewModel()
    let weatherVM = WeatherViewModel()

    private var cancellables = Set<AnyCancellable>()

    private var languageWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarItem()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: NSNotification.Name("OpenSettings"),
            object: nil
        )

        // 初回起動時: 言語選択
        if settingsManager.appLanguage.isEmpty {
            showLanguagePicker()
        } else {
            launchApp()
        }
    }

    private func showLanguagePicker() {
        let picker = LanguagePickerView { [weak self] language in
            self?.settingsManager.appLanguage = language
            self?.languageWindow?.close()
            self?.languageWindow = nil
            self?.launchApp()
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "NotchIsland"
        window.contentView = NSHostingView(rootView: picker)
        window.center()
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.languageWindow = window
    }

    private func launchApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupOverlayWindow()
            self?.startServices()
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "capsule.fill", accessibilityDescription: "NotchIsland")
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            toggleIsland()
            return
        }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggleIsland()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: L("menu.settings"), action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L("menu.quit"), action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func openSettings() {
        // 既存ウィンドウが閉じられてたらリセット
        if let window = settingsWindow, !window.isVisible {
            settingsWindow = nil
        }

        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            let settingsView = SettingsView()
                .environmentObject(settingsManager)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = L("settings.title")
            window.contentView = NSHostingView(rootView: settingsView)
            window.center()
            window.isReleasedWhenClosed = false
            window.level = .floating
            self.settingsWindow = window
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
        print("[NotchIsland] Settings window opened")
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func toggleIsland() {
        overlayWindowManager.toggleExpanded()
    }

    // MARK: - Overlay Window

    private func setupOverlayWindow() {
        overlayWindowManager = OverlayWindowManager(
            nowPlayingVM: nowPlayingVM,
            timerVM: timerVM,
            notificationVM: notificationVM,
            systemMonitorVM: systemMonitorVM,
            calendarVM: calendarVM,
            weatherVM: weatherVM,
            settingsManager: settingsManager
        )
        overlayWindowManager.showOverlay()
    }

    // MARK: - Services

    private func startServices() {
        nowPlayingVM.startMonitoring()
        systemMonitorVM.startMonitoring()
        calendarVM.requestAccessAndFetch()
        configureWeather()
        setupWindowTiling()

        // 設定変更を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    private func configureWeather() {
        if settingsManager.weatherLocationMode == .manual,
           let lat = Double(settingsManager.weatherLatitude),
           let lon = Double(settingsManager.weatherLongitude) {
            weatherVM.updateLocation(
                latitude: lat,
                longitude: lon,
                name: settingsManager.weatherLocationName.isEmpty ? "カスタム" : settingsManager.weatherLocationName
            )
        } else {
            weatherVM.useCurrentLocation()
        }
        weatherVM.startMonitoring()
    }

    private var lastWeatherConfig = ""

    @objc private func settingsDidChange() {
        // 天気設定が変わったときだけ再取得
        let currentConfig = "\(settingsManager.weatherLocationMode)|\(settingsManager.weatherLatitude)|\(settingsManager.weatherLongitude)|\(settingsManager.weatherLocationName)"
        if currentConfig != lastWeatherConfig {
            lastWeatherConfig = currentConfig
            configureWeather()
        }
    }

    private func setupWindowTiling() {
        let tiling = WindowTilingService.shared
        _ = tiling.requestAccessibility()
        tiling.registerHotkeys()
        tiling.startEdgeDetection()
    }
}
