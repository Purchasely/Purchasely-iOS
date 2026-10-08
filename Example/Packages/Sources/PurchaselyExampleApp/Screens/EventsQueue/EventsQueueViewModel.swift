//
//  EventsQueueViewModel.swift
//  PurchaselySampleV2
//
//  The "SDK events" screen: the events the SDK reports to the public event delegate while the
//  app runs. The list lives in memory only and starts empty at each launch.
//

import Foundation
import Purchasely

struct SDKEvent: Identifiable {
    let id = UUID()
    let date = Date()
    let name: String
    let properties: [String: Any]
}

/// Receives `PLYEventDelegate` callbacks. A singleton registered at SDK start, so the list also
/// holds the events sent before the screen opens.
final class SDKEventLog: NSObject, ObservableObject, PLYEventDelegate {

    static let shared = SDKEventLog()

    @Published private(set) var events: [SDKEvent] = []

    private let limit = 200

    func eventTriggered(_ event: PLYEvent, properties: [String: Any]?) {
        let entry = SDKEvent(name: event.name, properties: properties ?? [:])
        // The SDK may call the delegate from a background queue.
        DispatchQueue.main.async {
            self.events.insert(entry, at: 0)
            if self.events.count > self.limit { self.events.removeLast(self.events.count - self.limit) }
        }
    }

    func clear() {
        events = []
    }
}

class EventsQueueViewModel: ObservableObject {
    let log = SDKEventLog.shared
}
