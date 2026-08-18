import XCTest

@testable import NetcardioCore

final class DisplayTests: XCTestCase {
  func testCompactUsesBinaryThresholds() {
    XCTAssertEqual(Display.compact(0, unit: .bytes), "0")
    XCTAssertEqual(Display.compact(512, unit: .bytes), "512")
    XCTAssertEqual(Display.compact(1024, unit: .bytes), "1K")
    XCTAssertEqual(Display.compact(2048, unit: .bytes), "2K")
    // Threshold and divisor share the same base: exactly 1 MiB → "1.0M".
    XCTAssertEqual(Display.compact(1_048_576, unit: .bytes), "1.0M")
  }

  func testFullUsesBinaryUnits() {
    XCTAssertEqual(Display.full(500, unit: .bytes), "500 B/s")
    XCTAssertEqual(Display.full(1024, unit: .bytes), "1.0 KB/s")
    XCTAssertEqual(Display.full(1_048_576, unit: .bytes), "1.00 MB/s")
  }

  func testBitsUseDecimalUnitsAndTimesEight() {
    // 125,000 B/s × 8 = 1,000,000 bit/s = 1 Mbps (decimal).
    XCTAssertEqual(Display.compact(125_000, unit: .bits), "1.0M")
    XCTAssertEqual(Display.full(125_000, unit: .bits), "1.00 Mbps")
    // 1250 B/s × 8 = 10,000 bit/s = 10 Kbps.
    XCTAssertEqual(Display.full(1250, unit: .bits), "10.0 Kbps")
    // 10 B/s × 8 = 80 bit/s.
    XCTAssertEqual(Display.full(10, unit: .bits), "80 bps")
  }

  func testCompactClampsNegativeToZero() {
    XCTAssertEqual(Display.compact(-42, unit: .bytes), "0")
    XCTAssertEqual(Display.compact(-42, unit: .bits), "0")
  }

  func testLatencyFormatting() {
    XCTAssertEqual(Display.latency(nil), "—")
    XCTAssertEqual(Display.latency(28.4), "28 ms")
  }
}
