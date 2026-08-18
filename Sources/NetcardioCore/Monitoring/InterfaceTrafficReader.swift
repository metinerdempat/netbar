import Foundation

/// Reads raw interface byte counters from the kernel via `getifaddrs`.
///
/// DESIGN: all unsafe C bridging is confined to THIS file; the rest of the app only
/// ever sees the value type `InterfaceCounters`. `freeifaddrs` is guaranteed by
/// `defer` → no memory leak.
final class InterfaceTrafficReader: InterfaceCounterReading {
  func read() -> [String: InterfaceCounters] {
    var head: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&head) == 0 else { return [:] }
    defer { freeifaddrs(head) }

    var counters: [String: InterfaceCounters] = [:]
    var cursor = head
    while let entry = cursor {
      let interface = entry.pointee
      cursor = interface.ifa_next

      // Only link-layer (AF_LINK) records carry the byte counters.
      guard
        let address = interface.ifa_addr,
        address.pointee.sa_family == UInt8(AF_LINK),
        let rawData = interface.ifa_data
      else { continue }

      let name = String(cString: interface.ifa_name)
      guard !name.hasPrefix("lo") else { continue }  // don't count loopback traffic

      let link = rawData.assumingMemoryBound(to: if_data.self).pointee
      counters[name] = InterfaceCounters(receivedBytes: link.ifi_ibytes, sentBytes: link.ifi_obytes)
    }
    return counters
  }
}
