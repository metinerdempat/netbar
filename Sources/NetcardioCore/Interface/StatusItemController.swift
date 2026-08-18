import AppKit

/// The VIEW layer that manages the menu-bar item and its dropdown menu.
///
/// It only presents: it knows how the data should be shown, not where it comes from.
/// State arrives from the outside via `update(...)`. User actions (quit, unit selection)
/// are reported outward through callbacks (dependency inverted).
@MainActor
final class StatusItemController {
  private let statusItem: NSStatusItem
  private let downItem = NSMenuItem()
  private let upItem = NSMenuItem()
  private let pingItem = NSMenuItem()
  private let bytesUnitItem = NSMenuItem(title: "Bytes (MB/s)", action: nil, keyEquivalent: "")
  private let bitsUnitItem = NSMenuItem(title: "Bits (Mbps)", action: nil, keyEquivalent: "")
  private let font = NSFont.monospacedDigitSystemFont(ofSize: Config.UI.fontSize, weight: .regular)

  /// Called when "Quit" is clicked.
  var onQuit: (() -> Void)?
  /// Called when a throughput unit is selected.
  var onSelectUnit: ((RateUnit) -> Void)?

  init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    buildMenu()
    update(rate: .zero, latency: nil, unit: .bytes)
  }

  /// Draws the menu-bar title, the info rows and the unit checkmarks for the given state.
  func update(rate: NetworkRate, latency: Double?, unit: RateUnit) {
    let title = "↓\(Display.compact(rate.downBytesPerSecond, unit: unit)) "
      + "↑\(Display.compact(rate.upBytesPerSecond, unit: unit)) · \(Display.latency(latency))"
    statusItem.button?.attributedTitle = NSAttributedString(string: title, attributes: [.font: font])

    downItem.title = "Download:  \(Display.full(rate.downBytesPerSecond, unit: unit))"
    upItem.title = "Upload:  \(Display.full(rate.upBytesPerSecond, unit: unit))"
    pingItem.title = "Ping (\(Config.Ping.host)):  \(Display.latency(latency))"

    bytesUnitItem.state = unit == .bytes ? .on : .off
    bitsUnitItem.state = unit == .bits ? .on : .off
  }

  private func buildMenu() {
    let menu = NSMenu()
    for item in [downItem, upItem, pingItem] {
      item.isEnabled = false  // read-only info rows
      menu.addItem(item)
    }
    menu.addItem(.separator())
    menu.addItem(buildUnitMenuItem())
    menu.addItem(.separator())

    let quitItem = NSMenuItem(title: "Quit", action: #selector(quitTapped), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)

    statusItem.menu = menu
  }

  private func buildUnitMenuItem() -> NSMenuItem {
    bytesUnitItem.target = self
    bytesUnitItem.action = #selector(selectBytes)
    bitsUnitItem.target = self
    bitsUnitItem.action = #selector(selectBits)

    let submenu = NSMenu()
    submenu.addItem(bytesUnitItem)
    submenu.addItem(bitsUnitItem)

    let unitItem = NSMenuItem(title: "Unit", action: nil, keyEquivalent: "")
    unitItem.submenu = submenu
    return unitItem
  }

  @objc private func selectBytes() { onSelectUnit?(.bytes) }
  @objc private func selectBits() { onSelectUnit?(.bits) }
  @objc private func quitTapped() { onQuit?() }
}
