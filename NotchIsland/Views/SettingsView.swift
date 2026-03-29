import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        TabView {
            generalSettings
                .tabItem { Label(L("settings.tab.general"), systemImage: "gear") }

            featureSettings
                .tabItem { Label(L("settings.tab.features"), systemImage: "square.grid.2x2") }

            displaySettings
                .tabItem { Label(L("settings.tab.display"), systemImage: "display") }
        }
        .frame(minWidth: 420, minHeight: 380)
    }

    // MARK: - General

    private var generalSettings: some View {
        Form {
            Toggle(L("settings.launchAtLogin"), isOn: $settingsManager.launchAtLogin)
                .onChange(of: settingsManager.launchAtLogin) { newValue in
                    settingsManager.updateLoginItem(enabled: newValue)
                }

            Picker(L("settings.animationSpeed"), selection: $settingsManager.animationSpeed) {
                Text(L("settings.animationSpeed.slow")).tag(AnimationSpeed.slow)
                Text(L("settings.animationSpeed.normal")).tag(AnimationSpeed.normal)
                Text(L("settings.animationSpeed.fast")).tag(AnimationSpeed.fast)
            }

            Picker(L("settings.language"), selection: $settingsManager.appLanguage) {
                Text("日本語").tag("ja")
                Text("English").tag("en")
            }
        }
        .padding()
    }

    // MARK: - Features

    private var featureSettings: some View {
        Form {
            Section(L("settings.tab.features")) {
                Toggle(L("settings.features.nowPlaying"), isOn: $settingsManager.nowPlayingEnabled)
                Toggle(L("settings.features.timer"), isOn: $settingsManager.timerEnabled)
                Toggle(L("settings.features.notifications"), isOn: $settingsManager.notificationsEnabled)
                Toggle(L("settings.features.systemStats"), isOn: $settingsManager.systemStatsEnabled)
                Toggle(L("settings.features.calendar"), isOn: $settingsManager.calendarEnabled)
                Toggle(L("settings.features.weather"), isOn: $settingsManager.weatherEnabled)
            }

            Section(L("settings.weather.location")) {
                Picker(L("settings.weather.location"), selection: $settingsManager.weatherLocationMode) {
                    Text(L("settings.weather.currentLocation")).tag(WeatherLocationMode.current)
                    Text(L("settings.weather.manual")).tag(WeatherLocationMode.manual)
                }

                if settingsManager.weatherLocationMode == .manual {
                    TextField(L("settings.weather.locationName"), text: $settingsManager.weatherLocationName)
                    HStack {
                        TextField(L("settings.weather.latitude"), text: $settingsManager.weatherLatitude)
                            .frame(width: 120)
                        TextField(L("settings.weather.longitude"), text: $settingsManager.weatherLongitude)
                            .frame(width: 120)
                    }
                    Text(L("settings.weather.example"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(L("settings.features.priority")) {
                Text(L("settings.features.priorityDesc"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Display

    private var displaySettings: some View {
        Form {
            Section(L("settings.display.displayChoice")) {
                Picker(L("settings.display.displayChoice"), selection: $settingsManager.preferredDisplay) {
                    Text(L("settings.display.auto")).tag(DisplayPreference.auto)
                    Text(L("settings.display.builtIn")).tag(DisplayPreference.builtIn)
                    Text(L("settings.display.external")).tag(DisplayPreference.external)
                }
            }

            Section(L("settings.display.noNotch")) {
                Toggle(L("settings.display.alwaysVisible"), isOn: $settingsManager.alwaysVisible)
                Toggle(L("settings.display.deckMode"), isOn: $settingsManager.deckModeEnabled)
                Toggle(L("settings.display.expandOnHover"), isOn: $settingsManager.expandOnHover)
                Text(L("settings.display.expandOnHoverDesc"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Localization Helper

func L(_ key: String) -> String {
    var lang = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
    if lang.isEmpty {
        // システム言語にフォールバック
        let preferred = Locale.preferredLanguages.first ?? "en"
        lang = preferred.hasPrefix("ja") ? "ja" : "en"
    }
    guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
        return NSLocalizedString(key, comment: "")
    }
    return NSLocalizedString(key, bundle: bundle, comment: "")
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
    @AppStorage("appLanguage") var appLanguage = ""

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
