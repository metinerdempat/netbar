import XCTest

@testable import NetBarCore

/// A fake reader that returns pre-scripted counter frames in order.
private final class ScriptedReader: InterfaceCounterReading {
  private var frames: [[String: InterfaceCounters]]
  init(_ frames: [[String: InterfaceCounters]]) { self.frames = frames }
  func read() -> [String: InterfaceCounters] {
    frames.isEmpty ? [:] : frames.removeFirst()
  }
}

/// A deterministic clock: returns the next scripted time on each call.
private final class FakeClock {
  private var times: [Date]
  init(secondsSince1970: [TimeInterval]) {
    times = secondsSince1970.map { Date(timeIntervalSince1970: $0) }
  }
  func next() -> Date { times.removeFirst() }
}

final class NetworkMonitorTests: XCTestCase {
  func testComputesRateFromDeltaOverElapsedTime() {
    let reader = ScriptedReader([
      ["en0": InterfaceCounters(receivedBytes: 1000, sentBytes: 0)],  // init baseline
      ["en0": InterfaceCounters(receivedBytes: 3000, sentBytes: 500)],  // sample()
    ])
    let clock = FakeClock(secondsSince1970: [10, 11])  // 1s elapsed
    let monitor = NetworkMonitor(reader: reader, now: clock.next)

    let rate = monitor.sample()
    XCTAssertEqual(rate.downBytesPerSecond, 2000, accuracy: 0.0001)
    XCTAssertEqual(rate.upBytesPerSecond, 500, accuracy: 0.0001)
  }

  /// When a counter wraps at 2³², the difference must still be correct (single wrap).
  func testHandlesCounterWraparound() {
    let start = UInt32.max - 99  // 4_294_967_196
    let reader = ScriptedReader([
      ["en0": InterfaceCounters(receivedBytes: start, sentBytes: 0)],
      ["en0": InterfaceCounters(receivedBytes: 50, sentBytes: 0)],  // wrapped around
    ])
    let clock = FakeClock(secondsSince1970: [0, 1])
    let monitor = NetworkMonitor(reader: reader, now: clock.next)

    // 100 bytes (up to max) + 51 bytes (0..=50)? No: (50 &- (max-99)) = 150.
    let rate = monitor.sample()
    XCTAssertEqual(rate.downBytesPerSecond, 150, accuracy: 0.0001)
  }

  /// An interface unseen in the previous round contributes 0 that round (no fake spike).
  func testNewInterfaceContributesZero() {
    let reader = ScriptedReader([
      ["en0": InterfaceCounters(receivedBytes: 1000, sentBytes: 0)],
      [
        "en0": InterfaceCounters(receivedBytes: 1000, sentBytes: 0),
        "en1": InterfaceCounters(receivedBytes: 999_999, sentBytes: 0),  // new
      ]
    ])
    let clock = FakeClock(secondsSince1970: [0, 1])
    let monitor = NetworkMonitor(reader: reader, now: clock.next)

    let rate = monitor.sample()
    XCTAssertEqual(rate.downBytesPerSecond, 0, accuracy: 0.0001)
  }
}
