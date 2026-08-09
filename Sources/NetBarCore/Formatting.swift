import Foundation

/// Display unit for throughput. Bytes (data downloaded, binary) ↔ bits (link speed, decimal).
enum RateUnit: String {
  case bytes
  case bits

  /// Converts a bytes/sec value into this unit's raw value (×8 for bits).
  var multiplier: Double {
    self == .bits ? Config.Units.bitsPerByte : 1
  }

  var kilo: Double { self == .bits ? Config.Units.kilobit : Config.Units.kilobyte }
  var mega: Double { self == .bits ? Config.Units.megabit : Config.Units.megabyte }

  var baseSuffix: String { self == .bits ? "bps" : "B/s" }
  var kiloSuffix: String { self == .bits ? "Kbps" : "KB/s" }
  var megaSuffix: String { self == .bits ? "Mbps" : "MB/s" }
}

/// Turns raw numeric values into user-facing text.
///
/// Each unit (bytes/bits) carries its own thresholds and suffix → one code path,
/// consistent: threshold and divisor share the same base ("1.0M" begins exactly at
/// that unit's mega).
enum Display {
  /// Compact form for the menu-bar title: "1.2M", "240K", "56".
  static func compact(_ bytesPerSecond: Double, unit: RateUnit) -> String {
    let value = max(bytesPerSecond, 0) * unit.multiplier
    if value >= unit.mega {
      return String(format: "%.1fM", value / unit.mega)
    }
    if value >= unit.kilo {
      return String(format: "%.0fK", value / unit.kilo)
    }
    return String(format: "%.0f", value)
  }

  /// Full form for the dropdown menu: "1.20 MB/s" or "9.60 Mbps".
  static func full(_ bytesPerSecond: Double, unit: RateUnit) -> String {
    let value = max(bytesPerSecond, 0) * unit.multiplier
    if value >= unit.mega {
      return String(format: "%.2f", value / unit.mega) + " " + unit.megaSuffix
    }
    if value >= unit.kilo {
      return String(format: "%.1f", value / unit.kilo) + " " + unit.kiloSuffix
    }
    return String(format: "%.0f", value) + " " + unit.baseSuffix
  }

  /// Latency: "28 ms", or "—" when it can't be measured.
  static func latency(_ milliseconds: Double?) -> String {
    guard let milliseconds else { return "—" }
    return String(format: "%.0f ms", milliseconds)
  }
}
