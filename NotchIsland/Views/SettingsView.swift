import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        TabView {
            generalSettings
                .tabItem { Label("一般", systemImage: "gear") }

            featureSettings
                .tabItem { Label("機能", systemImage: "square.grid.2x2") }

            displaySettings
                .tabItem { Label("表示", systemImage: "display") }
        }
        .frame(width: 400, height: 320)
    }

    // MARK: - General

    private var generalSettings: some View {
        Form {
            Toggle("ログイン時に自動起動", isOn: $settingsManager.launchAtLogin)
                .onChange(of: settingsManager.launchAtLogin) { newValue in
                    settingsManager.updateLoginItem(enabled: newValue)
                }

            Picker("アニメーション速度", selection: $settingsManager.animationSpeed) {
                Text("遅い").tag(AnimationSpeed.slow)
                Text("普通").tag(AnimationSpeed.normal)
                Text("速い").tag(AnimationSpeed.fast)
            }
        }
        .padding()
    }

    // MARK: - Features

    private var featureSettings: some View {
        Form {
            Section("有効な機能") {
                Toggle("Now Playing（音楽再生）", isOn: $settingsManager.nowPlayingEnabled)
                Toggle("タイマー / ストップウォッチ", isOn: $settingsManager.timerEnabled)
                Toggle("通知表示", isOn: $settingsManager.notificationsEnabled)
                Toggle("バッテリー / CPU モニター", isOn: $settingsManager.systemStatsEnabled)
                Toggle("カレンダー（次の予定）", isOn: $settingsManager.calendarEnabled)
                Toggle("天気", isOn: $settingsManager.weatherEnabled)
            }

            Section("天気 - 場所設定") {
                Picker("場所", selection: $settingsManager.weatherLocationMode) {
                    Text("現在地").tag(WeatherLocationMode.current)
                    Text("手動設定").tag(WeatherLocationMode.manual)
                }

                if settingsManager.weatherLocationMode == .manual {
                    TextField("場所の名前", text: $settingsManager.weatherLocationName)
                    HStack {
                        TextField("緯度", text: $settingsManager.weatherLatitude)
                            .frame(width: 120)
                        TextField("経度", text: $settingsManager.weatherLongitude)
                            .frame(width: 120)
                    }
                    Text("例: 東京 → 35.6762, 139.6503")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("優先度（上が高い）") {
                Text("展開時のデフォルトタブや、Compact表示の優先度に影響します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Display

    private var displaySettings: some View {
        Form {
            Section("ディスプレイ") {
                Picker("表示ディスプレイ", selection: $settingsManager.preferredDisplay) {
                    Text("自動（メインディスプレイ）").tag(DisplayPreference.auto)
                    Text("内蔵ディスプレイ").tag(DisplayPreference.builtIn)
                    Text("外部ディスプレイ").tag(DisplayPreference.external)
                }
            }

            Section("ノッチなしMac") {
                Toggle("常に表示", isOn: $settingsManager.alwaysVisible)
                Toggle("Deckモード（ホバーで出現）", isOn: $settingsManager.deckModeEnabled)
                Toggle("ホバーで展開", isOn: $settingsManager.expandOnHover)
                Text("ホバーで展開: マウスを乗せると自動で展開します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Settings Manager

enum AnimationSpeed: String, Codable {
    case slow, normal, fast

    var springResponse: Double {
        switch self {
        case .slow: return 0.5
        case .normal: return 0.3
        case .fast: return 0.2
        }
    }

    var springDamping: Double {
        switch self {
        case .slow: return 0.8
        case .normal: return 0.7
        case .fast: return 0.65
        }
    }
}

enum DisplayPreference: String, Codable {
    case auto, builtIn, external
}

enum WeatherLocationMode: String, Codable {
    case current, manual
}

class SettingsManager: ObservableObject {
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("animationSpeed") var animationSpeed = AnimationSpeed.normal
    @AppStorage("nowPlayingEnabled") var nowPlayingEnabled = true
    @AppStorage("timerEnabled") var timerEnabled = true
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("systemStatsEnabled") var systemStatsEnabled = true
    @AppStorage("calendarEnabled") var calendarEnabled = true
    @AppStorage("preferredDisplay") var preferredDisplay = DisplayPreference.auto
    @AppStorage("deckModeEnabled") var deckModeEnabled = true
    @AppStorage("alwaysVisible") var alwaysVisible = false
    @AppStorage("expandOnHover") var expandOnHover = false
    @AppStorage("weatherEnabled") var weatherEnabled = true
    @AppStorage("weatherLocationMode") var weatherLocationMode = WeatherLocationMode.current
    @AppStorage("weatherLocationName") var weatherLocationName = ""
    @AppStorage("weatherLatitude") var weatherLatitude = ""
    @AppStorage("weatherLongitude") var weatherLongitude = ""

    func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Login item update failed: \(error)")
            }
        }
    }
}
