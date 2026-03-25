import Foundation

struct WeatherInfo {
    var temperature: Double = 0          // 摂氏
    var condition: String = ""           // 天気状態
    var symbolName: String = "cloud"     // SF Symbols名
    var locationName: String = ""
    var humidity: Double = 0             // 0-1
    var windSpeed: Double = 0            // km/h
    var highTemperature: Double = 0
    var lowTemperature: Double = 0
    var feelsLike: Double = 0
    var uvIndex: Int = 0

    var isEmpty: Bool {
        condition.isEmpty
    }

    var temperatureString: String {
        String(format: "%.0f°", temperature)
    }

    var highLowString: String {
        String(format: "H:%.0f° L:%.0f°", highTemperature, lowTemperature)
    }
}
