import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var vm: NowPlayingViewModel

    var body: some View {
        if vm.hasContent {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    // アルバムアート
                    if let art = vm.info.albumArt {
                        Image(nsImage: art)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.4))
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.info.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text(vm.info.artist)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    Spacer()
                }

                // プログレスバー
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * vm.info.progress, height: 3)
                    }
                }
                .frame(height: 3)

                // 時間表示
                HStack {
                    Text(formatTime(vm.info.elapsedTime))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)

                    Spacer()

                    Text(formatTime(vm.info.duration))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }

                // コントロール
                HStack(spacing: 30) {
                    Button(action: { vm.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    Button(action: { vm.togglePlayPause() }) {
                        Image(systemName: vm.info.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    Button(action: { vm.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.3))

                Text("\(L("nowPlaying.noContent"))")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
