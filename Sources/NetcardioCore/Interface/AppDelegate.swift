import AppKit

/// The app's COMPOSITION ROOT: wires up the services and the view, manages the timers,
/// and streams measurements into the view. It contains no business logic itself — it
/// only connects the pieces (dependencies go through abstract protocols).
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
  private let rateSampler: RateSampling
  private let latencyMonitor: LatencyMeasuring?
  private let preferences: Preferences
  private let statusItem = StatusItemController()

  private var rateTimer: Timer?
  private var pingTimer: Timer?

  private var latestRate: NetworkRate = .zero
  private var latestLatency: Double?
  private var unit: RateUnit

  public override init() {
    rateSampler = NetworkMonitor()
    latencyMonitor = PingMonitor(host: Config.Ping.host)
    preferences = Preferences()
    unit = preferences.rateUnit  // load the saved unit preference
    super.init()
  }

  public func applicationDidFinishLaunching(_ notification: Notification) {
    statusItem.onQuit = { NSApp.terminate(nil) }
    statusItem.onSelectUnit = { [weak self] newUnit in self?.selectUnit(newUnit) }
    render()
    startTimers()
    refreshLatency()  // fire the first ping immediately (no 3s wait)
  }

  public func applicationWillTerminate(_ notification: Notification) {
    rateTimer?.invalidate()
    pingTimer?.invalidate()
  }

  private func selectUnit(_ newUnit: RateUnit) {
    guard newUnit != unit else { return }
    unit = newUnit
    preferences.rateUnit = newUnit  // persist the preference
    render()
  }

  private func startTimers() {
    rateTimer = makeTimer(interval: Config.Rate.refreshInterval, selector: #selector(refreshRate))
    pingTimer = makeTimer(interval: Config.Ping.refreshInterval, selector: #selector(refreshLatency))
  }

  /// Builds a target-action timer added to the main run loop in `.common` mode.
  /// `.common` → keeps firing even while a menu is open. Selector dispatch runs on the
  /// main thread, so `@MainActor` methods are called without breaking actor isolation.
  private func makeTimer(interval: TimeInterval, selector: Selector) -> Timer {
    let timer = Timer(timeInterval: interval, target: self, selector: selector, userInfo: nil, repeats: true)
    RunLoop.main.add(timer, forMode: .common)
    return timer
  }

  @objc private func refreshRate() {
    latestRate = rateSampler.sample()
    render()
  }

  @objc private func refreshLatency() {
    latencyMonitor?.measure { [weak self] milliseconds in
      guard let self else { return }
      self.latestLatency = milliseconds
      self.render()
    }
  }

  private func render() {
    statusItem.update(rate: latestRate, latency: latestLatency, unit: unit)
  }
}
