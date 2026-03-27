import Foundation

struct SystemStats {
    var batteryLevel: Int = 0          // 0-100
    var isCharging: Bool = false
    var cpuUsage: Double = 0           // 0-100
    var memoryUsage: Double = 0        // 0-100
    var memoryUsedGB: Double = 0
    var memoryTotalGB: Double = 0
    var batteryTimeRemaining: Int? = nil // 分単位

    var batteryIcon: String {
        if isCharging {
            return "bolt.fill"
        }
        switch batteryLevel {
        case 0..<10: return "battery.0"
        case 10..<25: return "battery.25"
        case 25..<50: return "battery.25"
        case 50..<75: return "battery.50"
        case 75..<100: return "battery.75"
        default: return "battery.100"
        }
    }

    var batteryTimeString: String? {
        guard let minutes = batteryTimeRemaining, minutes > 0 else { return nil }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return String(format: L("system.hours"), hours, mins)
        }
        return String(format: L("system.minutes"), mins)
    }
}
