import Foundation
import AppKit
import Combine

// MARK: - MediaRemote Dynamic Loading

private let mediaRemoteBundle: CFBundle? = {
    let url = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
    return CFBundleCreate(kCFAllocatorDefault, url as CFURL)
}()

private func mrFunction<T>(_ name: String) -> T? {
    guard let bundle = mediaRemoteBundle else { return nil }
    guard let ptr = CFBundleGetFunctionPointerForName(bundle, name as CFString) else { return nil }
    return unsafeBitCast(ptr, to: T.self)
}

private typealias MRRegisterType = @convention(c) (DispatchQueue) -> Void
private typealias MRGetInfoType = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
private typealias MRSendCommandType = @convention(c) (UInt32, UnsafeRawPointer?) -> Bool

// MediaRemote commands
private let kMRPlay: UInt32 = 0
private let kMRPause: UInt32 = 1
private let kMRTogglePlayPause: UInt32 = 2
private let kMRNextTrack: UInt32 = 4
private let kMRPreviousTrack: UInt32 = 5

// MediaRemote info keys
private let kTitle = "kMRMediaRemoteNowPlayingInfoTitle"
private let kArtist = "kMRMediaRemoteNowPlayingInfoArtist"
private let kArtwork = "kMRMediaRemoteNowPlayingInfoArtworkData"
private let kDuration = "kMRMediaRemoteNowPlayingInfoDuration"
private let kElapsed = "kMRMediaRemoteNowPlayingInfoElapsedTime"
private let kPlaybackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"

class NowPlayingViewModel: ObservableObject {
    @Published var info = NowPlayingInfo()
    @Published var hasContent = false

    private var pollTimer: Timer?
    private var isAvailable = false

    private var registerFunc: MRRegisterType?
    private var getInfoFunc: MRGetInfoType?
    private var sendCommandFunc: MRSendCommandType?

    func startMonitoring() {
        // 動的にMediaRemote関数をロード
        registerFunc = mrFunction("MRMediaRemoteRegisterForNowPlayingNotifications")
        getInfoFunc = mrFunction("MRMediaRemoteGetNowPlayingInfo")
        sendCommandFunc = mrFunction("MRMediaRemoteSendCommand")

        guard registerFunc != nil, getInfoFunc != nil else {
            print("[NowPlaying] MediaRemote framework not available")
            return
        }

        isAvailable = true
        registerFunc?(DispatchQueue.main)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingInfoChanged),
            name: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingInfoChanged),
            name: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"),
            object: nil
        )

        fetchNowPlayingInfo()

        // 再生中でないときは頻繁にポーリングしない（10秒）
        pollTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchNowPlayingInfo()
        }
    }

    @objc private func nowPlayingInfoChanged() {
        fetchNowPlayingInfo()
    }

    private func fetchNowPlayingInfo() {
        guard isAvailable, let getInfo = getInfoFunc else { return }

        getInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self else { return }

            let title = info[kTitle] as? String ?? ""
            let artist = info[kArtist] as? String ?? ""
            let duration = info[kDuration] as? TimeInterval ?? 0
            let elapsed = info[kElapsed] as? TimeInterval ?? 0
            let playbackRate = info[kPlaybackRate] as? Double ?? 0

            var albumArt: NSImage? = nil
            if let artworkData = info[kArtwork] as? Data {
                albumArt = NSImage(data: artworkData)
            }

            self.info = NowPlayingInfo(
                title: title,
                artist: artist,
                albumArt: albumArt,
                isPlaying: playbackRate > 0,
                duration: duration,
                elapsedTime: elapsed
            )
            self.hasContent = !title.isEmpty
        }
    }

    // MARK: - Controls

    func togglePlayPause() {
        _ = sendCommandFunc?(kMRTogglePlayPause, nil)
    }

    func nextTrack() {
        _ = sendCommandFunc?(kMRNextTrack, nil)
    }

    func previousTrack() {
        _ = sendCommandFunc?(kMRPreviousTrack, nil)
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        stopMonitoring()
    }
}
