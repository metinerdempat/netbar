import Foundation

/// A tiny key-value store abstraction. We depend on this instead of `UserDefaults`
/// directly → an in-memory fake can be injected in tests.
protocol KeyValueStore: AnyObject {
  func readString(forKey key: String) -> String?
  func writeString(_ value: String, forKey key: String)
}

extension UserDefaults: KeyValueStore {
  func readString(forKey key: String) -> String? { string(forKey: key) }
  func writeString(_ value: String, forKey key: String) { set(value, forKey: key) }
}

/// Persists user preferences. For now, a single preference: the throughput unit.
final class Preferences {
  private let store: KeyValueStore
  private enum Key {
    static let rateUnit = "rateUnit"
  }

  init(store: KeyValueStore = UserDefaults.standard) {
    self.store = store
  }

  /// Throughput display unit. Defaults to bytes when unset or corrupt.
  var rateUnit: RateUnit {
    get { RateUnit(rawValue: store.readString(forKey: Key.rateUnit) ?? "") ?? .bytes }
    set { store.writeString(newValue.rawValue, forKey: Key.rateUnit) }
  }
}
