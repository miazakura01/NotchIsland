import SwiftUI

struct SystemStatsView: View {
    @ObservedObject var vm: SystemMonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // バッテリー
            HStack {
                Image(systemName: vm.stats.batteryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(vm.stats.isCharging ? .green : batteryColor)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(L("system.battery")) \(vm.stats.batteryLevel)%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)

                        if vm.stats.isCharging {
                            Text(L("system.charging"))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.green.opacity(0.15))
                                )
                        }
                    }

                    if let timeStr = vm.stats.batteryTimeString {
                        Text(vm.stats.isCharging ? String(format: L("system.chargeComplete"), timeStr) : String(format: L("system.timeRemaining"), timeStr))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    } else {
                        Text(vm.stats.isCharging ? "" : L("system.batteryPower"))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // バッテリーバー
                batteryBar
            }

            Divider().background(Color.white.opacity(0.15))

            // CPU
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "CPU %.1f%%", vm.stats.cpuUsage))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()

                // CPU使用率バー
                usageBar(value: vm.stats.cpuUsage / 100, color: cpuColor)
            }

            // メモリ
            HStack {
                Image(systemName: "memorychip")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%@ %.1f / %.0f GB", L("system.memory"), vm.stats.memoryUsedGB, vm.stats.memoryTotalGB))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()

                usageBar(value: vm.stats.memoryUsage / 100, color: .purple)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Components

    private var batteryBar: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.15))
                .frame(width: 60, height: 10)

            RoundedRectangle(cornerRadius: 3)
                .fill(batteryColor)
                .frame(width: 60 * CGFloat(vm.stats.batteryLevel) / 100, height: 10)
        }
    }

    private func usageBar(value: Double, color: Color) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.15))
                .frame(width: 60, height: 8)

            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 60 * min(CGFloat(value), 1.0), height: 8)
        }
    }

    private var batteryColor: Color {
        if vm.stats.batteryLevel <= 10 { return .red }
        if vm.stats.batteryLevel <= 20 { return .orange }
        if vm.stats.isCharging { return .green }
        return .green
    }

    private var cpuColor: Color {
        if vm.stats.cpuUsage > 80 { return .red }
        if vm.stats.cpuUsage > 50 { return .orange }
        return .blue
    }
}
