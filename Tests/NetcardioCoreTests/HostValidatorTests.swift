import XCTest

@testable import NetcardioCore

final class HostValidatorTests: XCTestCase {
  func testAcceptsValidHosts() {
    XCTAssertTrue(HostValidator.isValid("1.1.1.1"))
    XCTAssertTrue(HostValidator.isValid("google.com"))
    XCTAssertTrue(HostValidator.isValid("2001:db8::1"))
  }

  func testRejectsInjectionAndGarbage() {
    XCTAssertFalse(HostValidator.isValid(""))
    XCTAssertFalse(HostValidator.isValid("a b"))
    XCTAssertFalse(HostValidator.isValid("1.1.1.1; rm -rf /"))
    XCTAssertFalse(HostValidator.isValid("$(whoami)"))
    XCTAssertFalse(HostValidator.isValid(String(repeating: "a", count: 300)))
  }
}
