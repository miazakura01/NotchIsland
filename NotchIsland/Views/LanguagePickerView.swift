import SwiftUI

struct LanguagePickerView: View {
    @State private var selectedLanguage = "en"
    var onComplete: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("Welcome to NotchIsland")
                .font(.system(size: 20, weight: .bold))

            Text("NotchIslandへようこそ")
                .font(.system(size: 16))
                .foregroundColor(.gray)

            Divider()
                .padding(.horizontal, 40)

            Text("Select your language / 言語を選択")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                languageButton("English", code: "en", flag: "🇬🇧")
                languageButton("日本語", code: "ja", flag: "🇯🇵")
            }
            .padding(.horizontal, 40)

            Button(action: {
                onComplete(selectedLanguage)
            }) {
                Text(selectedLanguage == "ja" ? "続ける" : "Continue")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
        }
        .padding(30)
        .frame(width: 320, height: 380)
    }

    private func languageButton(_ name: String, code: String, flag: String) -> some View {
        Button(action: {
            selectedLanguage = code
        }) {
            HStack {
                Text(flag)
                    .font(.system(size: 20))
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                if selectedLanguage == code {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedLanguage == code ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(selectedLanguage == code ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
