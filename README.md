<p align="center">
  <img src="NotchIslandWithText.png" alt="NotchIsland" width="400">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

-----

# 🇯🇵 日本語
ダウンロード：[Release](https://github.com/miazakura01/NotchIsland/releases)

iPhoneのDynamic IslandをmacOSに。ノッチ周辺に便利な情報を表示するメニューバーアプリです。ノッチのないMacでは、フローティングピルとして動作します。

## 機能

### コア機能

- **ノッチ統合** — MacBookのノッチに自然にフィットするUI
- **フローティングピルモード** — ノッチのないMac（外部モニター・旧型MacBook）にも対応
- **デッキモード** — 普段は非表示、画面上部にホバーすると出現
- **Liquid Glass UI** — ブラー＆グラデーションによる半透明ガラス風デザイン

### モジュール

- **再生中** — MediaRemoteを使い、再生中の音楽（曲名・アーティスト・アルバムアート・コントロール）を表示
- **タイマー / ストップウォッチ** — カウントダウンタイマーとラップタイム付きストップウォッチ
- **天気** — 現在の天気・気温・湿度・風速・UVインデックス（WeatherKit使用）
- **システムモニター** — バッテリー残量・充電状態・CPU使用率・メモリ使用率
- **カレンダー** — macOS標準カレンダーの予定を表示（EventKit）
- **通知** — システム通知をDynamic Island内に表示

### ウィンドウタイリング（内蔵）

Magnetライクなウィンドウ管理機能を搭載しています。

|ショートカット              |動作   |
|---------------------|-----|
|`Ctrl+Option+←`      |左半分  |
|`Ctrl+Option+→`      |右半分  |
|`Ctrl+Option+↑`      |最大化  |
|`Ctrl+Option+↓`      |中央配置 |
|`Ctrl+Option+Shift+←`|左上1/4|
|`Ctrl+Option+Shift+→`|右上1/4|
|`Ctrl+Option+Shift+↓`|左下1/4|
|`Ctrl+Option+Shift+↑`|右下1/4|
|`Ctrl+Option+Return` |最大化  |
|`Ctrl+Option+C`      |中央配置 |

画面端へのドラッグスナップにも対応しています。

## 必要要件

- macOS 13.0（Ventura）以降
- Xcode 15.0以上
- Apple Developerアカウント（WeatherKit用）
- アクセシビリティ権限（ウィンドウタイリング用）

## ビルド

```bash
# xcodegen をインストール（未導入の場合）
brew install xcodegen

# Xcode プロジェクトを生成
cd NotchIsland
xcodegen generate

# Xcode で開く
open NotchIsland.xcodeproj
```

## セットアップ

### WeatherKit

1. [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/) でWeatherKit機能付きのApp IDを登録
1. **Capabilities** と **App Services** の両方でWeatherKitを有効化
1. Developer IDプロビジョニングプロファイルを作成

### アクセシビリティ（ウィンドウタイリング）

初回起動時にアクセシビリティ権限を要求します。**システム設定 → プライバシーとセキュリティ → アクセシビリティ** で許可してください。

## アーキテクチャ

```
NotchIsland/
├── NotchIslandApp.swift          # エントリポイント
├── AppDelegate.swift             # メニューバー、ウィンドウ管理、サービス
├── Models/                       # データモデル
├── ViewModels/                   # MVVM ビューモデル
├── Views/                        # SwiftUI ビュー
├── Services/                     # NotchDetector, OverlayWindow, Tiling
├── Utils/                        # 拡張、定数
└── Resources/                    # アセット
```

- **UI**: SwiftUI + AppKit（NSPanel オーバーレイ）
- **アーキテクチャ**: MVVM
- **天気**: WeatherKit（ネイティブフレームワーク）
- **再生中**: MediaRemote（プライベートフレームワーク、動的ロード）
- **システム情報**: IOKit + host_processor_info
- **カレンダー**: EventKit
- **ウィンドウタイリング**: Accessibility API（AXUIElement）+ Carbon ホットキー

## 帰属表示

天気データは **Apple Weather** を使用しています。[データソース](https://weatherkit.apple.com/legal-attribution.html)

## ライセンス

MIT License

-----

# 🇬🇧 English
Download: [Release](https://github.com/miazakura01/NotchIsland/releases)

iPhone-style Dynamic Island for macOS. Displays useful information around the notch area, or as a floating pill on non-notch Macs.

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

|Shortcut             |Action              |
|---------------------|--------------------|
|`Ctrl+Option+←`      |Left half           |
|`Ctrl+Option+→`      |Right half          |
|`Ctrl+Option+↑`      |Maximize            |
|`Ctrl+Option+↓`      |Center              |
|`Ctrl+Option+Shift+←`|Top-left quarter    |
|`Ctrl+Option+Shift+→`|Top-right quarter   |
|`Ctrl+Option+Shift+↓`|Bottom-left quarter |
|`Ctrl+Option+Shift+↑`|Bottom-right quarter|
|`Ctrl+Option+Return` |Maximize            |
|`Ctrl+Option+C`      |Center              |

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
1. Enable both **Capabilities** and **App Services** for WeatherKit
1. Create a Developer ID provisioning profile

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

Weather data powered by **Apple Weather**. [Data Sources](https://weatherkit.apple.com/legal-attribution.html)

## License

MIT License
