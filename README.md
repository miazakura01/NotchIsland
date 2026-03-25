# NotchIsland

![NotchIsland](NotchIslandWithText.png)

iPhone-style Dynamic Island for macOS. Displays useful information around the notch area (or as a floating pill on non-notch Macs).

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Core
- **Notch Integration** — Seamlessly wraps around the MacBook notch
- **Floating Pill Mode** — Works on non-notch Macs (external monitors, older MacBooks)
- **Deck Mode** — Hidden by default, appears on hover at the top of the screen
- **Liquid Glass UI** — Translucent, glass-like design with blur and gradient effects

### Modules
- **Now Playing** — Shows currently playing music (title, artist, album art, controls) via MediaRemote
- **Timer / Stopwatch** — Countdown timer and stopwatch with lap times
- **Weather** — Current weather, temperature, humidity, wind, UV index (powered by WeatherKit)
- **System Monitor** — Battery level, charging status, CPU usage, memory usage
- **Calendar** — Upcoming events from macOS Calendar (EventKit)
- **Notifications** — Displays system notifications in the Dynamic Island

### Window Tiling (Built-in)
Magnet-like window management:

| Shortcut | Action |
|---|---|
| `Ctrl+Option+←` | Left half |
| `Ctrl+Option+→` | Right half |
| `Ctrl+Option+↑` | Maximize |
| `Ctrl+Option+↓` | Center |
| `Ctrl+Option+Shift+←` | Top-left quarter |
| `Ctrl+Option+Shift+→` | Top-right quarter |
| `Ctrl+Option+Shift+↓` | Bottom-left quarter |
| `Ctrl+Option+Shift+↑` | Bottom-right quarter |
| `Ctrl+Option+Return` | Maximize |
| `Ctrl+Option+C` | Center |

Edge-drag snapping is also supported.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+
- Apple Developer account (for WeatherKit)
- Accessibility permission (for window tiling)

## Build

```bash
# Install xcodegen if not already installed
brew install xcodegen

# Generate Xcode project
cd NotchIsland
xcodegen generate

# Open in Xcode
open NotchIsland.xcodeproj
```

## Setup

### WeatherKit
1. Register an App ID with WeatherKit capability at [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/)
2. Enable both **Capabilities** and **App Services** for WeatherKit
3. Create a Developer ID provisioning profile

### Accessibility (Window Tiling)
On first launch, the app will request Accessibility permission. Grant it in **System Settings → Privacy & Security → Accessibility**.

## Architecture

```
NotchIsland/
├── NotchIslandApp.swift          # Entry point
├── AppDelegate.swift             # Menu bar, window management, services
├── Models/                       # Data models
├── ViewModels/                   # MVVM view models
├── Views/                        # SwiftUI views
├── Services/                     # NotchDetector, OverlayWindow, Tiling
├── Utils/                        # Extensions, constants
└── Resources/                    # Assets
```

- **UI**: SwiftUI + AppKit (NSPanel overlay)
- **Architecture**: MVVM
- **Weather**: WeatherKit (native framework)
- **Now Playing**: MediaRemote (private framework, dynamic loading)
- **System Stats**: IOKit + host_processor_info
- **Calendar**: EventKit
- **Window Tiling**: Accessibility API (AXUIElement) + Carbon hotkeys

## Attribution

Weather data powered by  **Apple Weather**. [Data Sources](https://weatherkit.apple.com/legal-attribution.html)

## License

MIT License. See [LICENSE](LICENSE) for details.
