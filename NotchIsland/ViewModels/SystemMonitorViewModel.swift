import Foundation
import IOKit.ps
import Combine

class SystemMonitorViewModel: ObservableObject {
    @Published var stats = SystemStats()

    private var pollTimer: Timer?

    func startMonitoring() {
        updateStats()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    private func updateStats() {
        updateBattery()
        updateCPU()
        updateMemory()
    }

    // MARK: - Battery (IOKit)

    private func updateBattery() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef)?.takeUnretainedValue() as? [String: Any]
        else { return }

        let capacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
        let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
        let powerSource = description[kIOPSPowerSourceStateKey] as? String
        let timeRemaining = description[kIOPSTimeToEmptyKey] as? Int

        // AC電源接続中 or 充電中
        let isOnPower = isCharging || powerSource == kIOPSACPowerValue

        stats.batteryLevel = Int(Double(capacity) / Double(maxCapacity) * 100)
        stats.isCharging = isOnPower
        stats.batteryTimeRemaining = timeRemaining

        print("[Battery] level: \(stats.batteryLevel)%, charging: \(isCharging), powerSource: \(powerSource ?? "nil"), isOnPower: \(isOnPower)")
    }

    // MARK: - CPU

    private func updateCPU() {
        var numCPU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPU,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else { return }

        var totalUser: Int32 = 0
        var totalSystem: Int32 = 0
        var totalIdle: Int32 = 0

        for i in 0..<Int(numCPU) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += cpuInfo[offset + Int(CPU_STATE_USER)]
            totalSystem += cpuInfo[offset + Int(CPU_STATE_SYSTEM)]
            totalIdle += cpuInfo[offset + Int(CPU_STATE_IDLE)]
        }

        let total = Double(totalUser + totalSystem + totalIdle)
        if total > 0 {
            stats.cpuUsage = Double(totalUser + totalSystem) / total * 100
        }

        // メモリ解放
        let size = Int(numCPUInfo) * MemoryLayout<integer_t>.size
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(size))
    }

    // MARK: - Memory

    private func updateMemory() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = Double(vm_kernel_page_size)
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize

        let used = (active + wired + compressed) / (1024 * 1024 * 1024)

        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)

        self.stats.memoryUsedGB = used
        self.stats.memoryTotalGB = totalMemory
        self.stats.memoryUsage = (used / totalMemory) * 100
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    deinit {
        stopMonitoring()
    }
}
