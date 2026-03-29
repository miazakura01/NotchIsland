import Foundation
import WeatherKit
import CoreLocation
import Combine

class WeatherViewModel: NSObject, ObservableObject {
    @Published var weather = WeatherInfo()
    @Published var hasContent = false
    @Published var errorMessage: String?

    private var refreshTimer: Timer?
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    var customLatitude: Double?
    var customLongitude: Double?
    var customLocationName: String?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func startMonitoring() {
        refreshTimer?.invalidate()

        if let lat = customLatitude, let lon = customLongitude {
            let location = CLLocation(latitude: lat, longitude: lon)
            currentLocation = location
            weather.locationName = customLocationName ?? "カスタム"
            fetchWeather(for: location)
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.startUpdatingLocation()
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            guard let self = self, let location = self.currentLocation else { return }
            self.fetchWeather(for: location)
        }
    }

    func updateLocation(latitude: Double, longitude: Double, name: String) {
        customLatitude = latitude
        customLongitude = longitude
        customLocationName = name
        let location = CLLocation(latitude: latitude, longitude: longitude)
        currentLocation = location
        weather.locationName = name
        fetchWeather(for: location)
    }

    func useCurrentLocation() {
        customLatitude = nil
        customLongitude = nil
        customLocationName = nil
        locationManager.startUpdatingLocation()
    }

    private func fetchWeather(for location: CLLocation) {
        guard #available(macOS 13.0, *) else {
            self.errorMessage = "macOS 13以降が必要です"
            return
        }
        Task { @MainActor in
            await self.fetchWeatherAsync(for: location)
        }
    }

    @available(macOS 13.0, *)
    private func fetchWeatherAsync(for location: CLLocation) async {
        do {
            let weatherService = WeatherService.shared
            let result = try await weatherService.weather(for: location)

            let current = result.currentWeather
            let daily = result.dailyForecast.first

            self.weather = WeatherInfo(
                temperature: current.temperature.value,
                condition: localizedCondition(current.condition.rawValue),
                symbolName: current.symbolName,
                locationName: self.weather.locationName,
                humidity: current.humidity,
                windSpeed: current.wind.speed.value,
                highTemperature: daily?.highTemperature.value ?? 0,
                lowTemperature: daily?.lowTemperature.value ?? 0,
                feelsLike: current.apparentTemperature.value,
                uvIndex: current.uvIndex.value
            )
            self.hasContent = true
            self.errorMessage = nil
        } catch {
            self.errorMessage = "天気取得エラー: \(error.localizedDescription)"
            print("[Weather] Error: \(error)")
        }
    }

    private func localizedCondition(_ code: String) -> String {
        // WeatherKitは小文字始まり(mostlyClear)、キーは大文字始まり(MostlyClear)
        let capitalized = code.prefix(1).uppercased() + code.dropFirst()
        let key = "weather.condition.\(capitalized)"
        let result = L(key)
        return result == key ? code : result
    }

    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let name = placemarks?.first?.locality {
                DispatchQueue.main.async {
                    self?.weather.locationName = name
                }
            }
        }
    }

    func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        locationManager.stopUpdatingLocation()
    }

    deinit {
        stopMonitoring()
    }
}

extension WeatherViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard customLatitude == nil, let location = locations.last else { return }
        currentLocation = location
        reverseGeocode(location)
        fetchWeather(for: location)
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Weather] Location error: \(error)")
        errorMessage = L("weather.error.location")
    }
}
