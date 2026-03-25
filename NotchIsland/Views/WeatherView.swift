import SwiftUI

// MARK: - Compact Weather

struct CompactWeatherView: View {
    @ObservedObject var vm: WeatherViewModel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: vm.weather.symbolName)
                .font(.system(size: 13))
                .symbolRenderingMode(.multicolor)

            Text(vm.weather.temperatureString)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Text(vm.weather.locationName)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
}

// MARK: - Expanded Weather

struct WeatherView: View {
    @ObservedObject var vm: WeatherViewModel

    var body: some View {
        if vm.hasContent {
            VStack(alignment: .leading, spacing: 10) {
                // メイン
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.weather.locationName)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        HStack(alignment: .top, spacing: 4) {
                            Text(vm.weather.temperatureString)
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.white)
                        }

                        Text(vm.weather.condition)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))

                        Text(vm.weather.highLowString)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: vm.weather.symbolName)
                        .font(.system(size: 42))
                        .symbolRenderingMode(.multicolor)
                }

                Divider().background(Color.white.opacity(0.15))

                // 詳細
                HStack(spacing: 16) {
                    weatherDetail(icon: "thermometer", label: "体感", value: String(format: "%.0f°", vm.weather.feelsLike))
                    weatherDetail(icon: "humidity", label: "湿度", value: String(format: "%.0f%%", vm.weather.humidity * 100))
                    weatherDetail(icon: "wind", label: "風速", value: String(format: "%.0fkm/h", vm.weather.windSpeed))
                    weatherDetail(icon: "sun.max", label: "UV", value: "\(vm.weather.uvIndex)")
                }

                // Apple Weather アトリビューション
                HStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 8))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("Weather")
                        .font(.system(size: 8))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("—")
                        .font(.system(size: 8))
                        .foregroundColor(.gray.opacity(0.4))
                    Link("データソース", destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
                        .font(.system(size: 8))
                        .foregroundColor(.gray.opacity(0.6))
                }

                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        } else if let error = vm.errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.icloud")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("天気を取得中...")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func weatherDetail(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
    }
}
