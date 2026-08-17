import Foundation

// MARK: - Protocol

/// A source that measures network latency (ping).
protocol LatencyMeasuring: AnyObject {
  /// Measures asynchronously and delivers the result on the MAIN queue. `nil` if unreachable.
  func measure(completion: @escaping (Double?) -> Void)
}

// MARK: - Pure helpers (side-effect free → testable)

/// Validates the ping target.
///
/// SECURITY — defense in depth: arguments are passed to the subprocess as an ARRAY,
/// so shell/command injection is already impossible. This layer is an extra guard:
/// it only allows valid hostname / IPv4 / IPv6 characters, so an unexpected input
/// never reaches `ping` in the first place.
enum HostValidator {
  private static let allowed = CharacterSet(
    charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-:"
  )

  static func isValid(_ host: String) -> Bool {
    guard !host.isEmpty, host.count <= 253 else { return false }
    return host.unicodeScalars.allSatisfy { allowed.contains($0) }
  }
}

/// A pure function that parses latency out of `ping` output.
enum PingOutputParser {
  /// Extracts `23.456` from a "... time=23.456 ms ..." pattern. `nil` if absent.
  /// `Double(_:)` is locale-independent; it reads `ping` output whose decimal separator is ".".
  static func latencyMilliseconds(from output: String) -> Double? {
    guard let marker = output.range(of: "time=") else { return nil }
    let tail = output[marker.upperBound...]
    let number = tail.prefix { $0.isNumber || $0 == "." }
    return Double(number)
  }
}

// MARK: - Monitor

/// Sends a single ICMP packet to a host and measures the latency (ms).
///
/// SECURITY:
///  • `/sbin/ping` is invoked by ABSOLUTE path → immune to PATH hijacking.
///  • Arguments are passed as an ARRAY, no shell → command injection is impossible.
///  • The host is additionally validated by `HostValidator` (defense in depth).
///  • The subprocess gets an EMPTY environment → minimal leakage / attack surface.
///  • One measurement at a time (in-flight lock) → no process pile-up.
final class PingMonitor: LatencyMeasuring {
  private let host: String
  private let queue = DispatchQueue(label: "com.netbar.ping", qos: .utility)
  private var isMeasuring = false  // read/written on the main queue only

  /// Returns `nil` for an invalid host (keeps the caller on the safe side).
  init?(host: String) {
    guard HostValidator.isValid(host) else { return nil }
    self.host = host
  }

  func measure(completion: @escaping (Double?) -> Void) {
    guard !isMeasuring else { return }  // if a previous measurement is running, don't start another
    isMeasuring = true

    queue.async { [weak self, host] in
      let latency = Self.runPing(host: host)
      DispatchQueue.main.async {
        self?.isMeasuring = false
        completion(latency)
      }
    }
  }

  private static func runPing(host: String) -> Double? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/sbin/ping")
    process.arguments = ["-c", "1", "-t", String(Config.Ping.timeoutSeconds), host]
    process.environment = [:]  // minimal environment; ping runs by absolute path, spawns nothing

    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice

    do {
      try process.run()
    } catch {
      return nil
    }

    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    guard process.terminationStatus == 0, let text = String(data: data, encoding: .utf8) else {
      return nil
    }
    return PingOutputParser.latencyMilliseconds(from: text)
  }
}
