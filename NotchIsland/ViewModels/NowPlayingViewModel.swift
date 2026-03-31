import Foundation
import AppKit
import Combine

class NowPlayingViewModel: ObservableObject {
    @Published var info = NowPlayingInfo()
    @Published var hasContent = false

    private var pollTimer: Timer?
    private var streamProcess: Process?

    // MediaHelper paths
    private var perlScript: String {
        Bundle.main.path(forResource: "media-helper", ofType: "pl") ?? ""
    }
    private var frameworkPath: String {
        let fw = Bundle.main.privateFrameworksPath ?? ""
        return "\(fw)/MediaHelper.framework"
    }

    func startMonitoring() {
        fetchNowPlayingInfo()

        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.fetchNowPlayingInfo()
        }
    }

    private func fetchNowPlayingInfo() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let json = self.runMediaHelper(command: "get")

            DispatchQueue.main.async {
                self.parseNowPlayingJSON(json)
            }
        }
    }

    private func parseNowPlayingJSON(_ json: String?) {
        guard let json = json, json != "null", !json.isEmpty,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            info = NowPlayingInfo()
            hasContent = false
            return
        }

        let title = dict["title"] as? String ?? ""
        let artist = dict["artist"] as? String ?? ""
        let duration = dict["duration"] as? TimeInterval ?? 0
        let elapsed = dict["elapsedTime"] as? TimeInterval ?? 0
        let isPlaying = dict["playing"] as? Bool ?? false

        var albumArt: NSImage? = nil
        if let artB64 = dict["artworkData"] as? String, !artB64.isEmpty,
           let artData = Data(base64Encoded: artB64) {
            albumArt = NSImage(data: artData)
        }

        info = NowPlayingInfo(
            title: title,
            artist: artist,
            albumArt: albumArt,
            isPlaying: isPlaying,
            duration: duration,
            elapsedTime: elapsed
        )
        hasContent = !title.isEmpty
    }

    // MARK: - Controls

    func togglePlayPause() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runMediaHelper(command: "send", args: ["2"])
        }
    }

    func nextTrack() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runMediaHelper(command: "send", args: ["4"])
        }
    }

    func previousTrack() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runMediaHelper(command: "send", args: ["5"])
        }
    }

    // MARK: - Process

    @discardableResult
    private func runMediaHelper(command: String, args: [String] = []) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [perlScript, frameworkPath, command] + args
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("[NowPlaying] Process error: \(error)")
            return nil
        }
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
        streamProcess?.terminate()
    }

    deinit {
        stopMonitoring()
    }
}
