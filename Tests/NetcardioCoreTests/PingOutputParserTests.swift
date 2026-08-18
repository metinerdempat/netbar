import XCTest

@testable import NetcardioCore

final class PingOutputParserTests: XCTestCase {
  func testExtractsLatencyFromRealOutput() {
    let output = """
      PING 1.1.1.1 (1.1.1.1): 56 data bytes
      64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=23.456 ms
      """
    XCTAssertEqual(PingOutputParser.latencyMilliseconds(from: output), 23.456)
  }

  func testReturnsNilWhenNoTiming() {
    let output = "Request timeout for icmp_seq 0"
    XCTAssertNil(PingOutputParser.latencyMilliseconds(from: output))
  }

  func testParsesIntegerLikeTiming() {
    XCTAssertEqual(PingOutputParser.latencyMilliseconds(from: "time=1 ms"), 1)
  }
}
