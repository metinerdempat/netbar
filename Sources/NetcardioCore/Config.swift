import Foundation

/// Every tunable constant in one place (DRY).
/// No magic numbers elsewhere — thresholds and intervals all come from here.
enum Config {
  enum Ping {
    /// Target for latency measurement. An IP is preferred (keeps DNS out of the reading).
    static let host = "1.1.1.1"
    /// `ping -t` timeout, in seconds.
    static let timeoutSeconds = 2
    /// Ping refresh interval, in seconds. Larger than the timeout → measurements never overlap.
    static let refreshInterval: TimeInterval = 3
  }

  enum Rate {
    /// Throughput refresh interval, in seconds.
    static let refreshInterval: TimeInterval = 1
  }

  /// Unit bases. Bytes are binary (1 KB = 1024 B), bits are decimal (1 Mbps = 10⁶ bits)
  /// — the standard distinction in networking.
  enum Units {
    static let kilobyte: Double = 1024
    static let megabyte: Double = 1024 * 1024
    static let kilobit: Double = 1000
    static let megabit: Double = 1000 * 1000
    /// 1 byte = 8 bits.
    static let bitsPerByte: Double = 8
  }

  enum UI {
    static let fontSize: CGFloat = 12
  }
}
