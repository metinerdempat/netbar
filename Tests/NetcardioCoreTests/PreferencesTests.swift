import XCTest

@testable import NetcardioCore

/// An in-memory key-value store for tests that never touches disk.
private final class InMemoryStore: KeyValueStore {
  private var storage: [String: String] = [:]
  func readString(forKey key: String) -> String? { storage[key] }
  func writeString(_ value: String, forKey key: String) { storage[key] = value }
}

final class PreferencesTests: XCTestCase {
  func testDefaultsToBytesWhenUnset() {
    let preferences = Preferences(store: InMemoryStore())
    XCTAssertEqual(preferences.rateUnit, .bytes)
  }

  func testPersistsAndReadsBackSelectedUnit() {
    let store = InMemoryStore()
    Preferences(store: store).rateUnit = .bits
    // A fresh instance reading the same store must see the value (persistence).
    XCTAssertEqual(Preferences(store: store).rateUnit, .bits)
  }

  func testFallsBackToBytesOnCorruptValue() {
    let store = InMemoryStore()
    store.writeString("garbage", forKey: "rateUnit")
    XCTAssertEqual(Preferences(store: store).rateUnit, .bytes)
  }
}
