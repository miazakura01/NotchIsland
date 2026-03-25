import AppKit

struct NowPlayingInfo {
    var title: String = ""
    var artist: String = ""
    var albumArt: NSImage?
    var isPlaying: Bool = false
    var duration: TimeInterval = 0
    var elapsedTime: TimeInterval = 0
    var appBundleIdentifier: String?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(elapsedTime / duration, 1.0)
    }

    var isEmpty: Bool {
        title.isEmpty && artist.isEmpty
    }
}
