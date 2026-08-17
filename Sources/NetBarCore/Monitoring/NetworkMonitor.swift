import Foundation

// MARK: - Domain types

/// Instantaneous network throughput at a point in time (bytes / second).
struct NetworkRate: Equatable {
  let downBytesPerSecond: Double
  let upBytesPerSecond: Double

  static let zero = NetworkRate(downBytesPerSecond: 0, upBytesPerSecond: 0)
}

/// Cumulative byte counters for a single network interface.
/// macOS keeps these as 32-bit and they wrap on overflow; we compute the delta with
/// overflow-safe (`&-`) subtraction, so we keep the raw 32-bit value.
struct InterfaceCounters: Equatable {
  let receivedBytes: UInt32
  let sentBytes: UInt32
}

// MARK: - Protocols (dependency inversion → testability)

/// A source that produces instantaneous network throughput.
protocol RateSampling: AnyObject {
  func sample() -> NetworkRate
}

/// A source that reads raw interface counters (abstracts the unsafe C bridging).
protocol InterfaceCounterReading {
  func read() -> [String: InterfaceCounters]
}

// MARK: - Implementation

/// Turns raw cumulative counters into instantaneous throughput (bytes/sec).
///
/// macOS interface counters are 32-bit and cumulative. We store the previous value
/// per interface and take an overflow-safe (`&-`) difference, so even when a counter
/// wraps at 2³² there is no single-sample spike.
///
/// Dependencies (the counter reader and the clock) are injectable → deterministic tests.
final class NetworkMonitor: RateSampling {
  private let reader: InterfaceCounterReading
  private let now: () -> Date

  private var previous: [String: InterfaceCounters]
  private var lastSampledAt: Date

  init(
    reader: InterfaceCounterReading = InterfaceTrafficReader(),
    now: @escaping () -> Date = Date.init
  ) {
    self.reader = reader
    self.now = now
    self.lastSampledAt = now()
    self.previous = reader.read()  // establish a baseline so the first sample is correct
  }

  func sample() -> NetworkRate {
    let current = reader.read()
    let timestamp = now()
    let elapsed = max(timestamp.timeIntervalSince(lastSampledAt), 0.001)  // guard against divide-by-zero
    lastSampledAt = timestamp

    var deltaDown: UInt64 = 0
    var deltaUp: UInt64 = 0
    for (name, sample) in current {
      guard let earlier = previous[name] else { continue }  // new interface → contributes 0 this round
      // Overflow-safe difference: UInt32 wrapping subtraction handles a single wrap correctly.
      deltaDown += UInt64(sample.receivedBytes &- earlier.receivedBytes)
      deltaUp += UInt64(sample.sentBytes &- earlier.sentBytes)
    }
    previous = current

    return NetworkRate(
      downBytesPerSecond: Double(deltaDown) / elapsed,
      upBytesPerSecond: Double(deltaUp) / elapsed
    )
  }
}
