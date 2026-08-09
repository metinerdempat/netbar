import AppKit
import NetBarCore

/// Application entry point. `@MainActor` → all setup runs on the main thread
/// (Swift concurrency safety). All logic lives in NetBarCore; this is a thin shell.
@main
enum NetBarApp {
  @MainActor
  static func main() {
    // Menu-bar app: shows no Dock icon / app menu (.accessory).
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.setActivationPolicy(.accessory)
    application.run()
  }
}
