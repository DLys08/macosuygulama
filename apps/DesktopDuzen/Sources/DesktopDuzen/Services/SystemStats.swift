import Foundation
import Darwin

/// Real CPU and memory figures from the Mach host APIs (no shell-outs, no polling threads).
public final class SystemStats {
    private var previousTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?

    public init() {}

    /// Overall CPU usage since the previous call, 0...100. The first call returns the load since boot.
    public func cpuUsagePercent() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let user = UInt64(info.cpu_ticks.0), system = UInt64(info.cpu_ticks.1)
        let idle = UInt64(info.cpu_ticks.2), nice = UInt64(info.cpu_ticks.3)
        defer { previousTicks = (user, system, idle, nice) }
        let prev = previousTicks ?? (0, 0, 0, 0)
        let busy = Double((user &- prev.user) + (system &- prev.system) + (nice &- prev.nice))
        let total = busy + Double(idle &- prev.idle)
        return total > 0 ? min(100, max(0, busy / total * 100)) : 0
    }

    /// Used memory (active + wired + compressed) as a share of physical memory, 0...100.
    public func memoryUsagePercent() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let page = Double(vm_kernel_page_size)
        let used = (Double(stats.active_count) + Double(stats.wire_count) + Double(stats.compressor_page_count)) * page
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        return total > 0 ? min(100, max(0, used / total * 100)) : 0
    }
}
