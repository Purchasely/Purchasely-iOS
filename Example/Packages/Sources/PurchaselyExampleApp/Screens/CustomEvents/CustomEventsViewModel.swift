//
//  CustomEventsViewModel.swift
//  PurchaselySampleV2
//
//  The Custom Events screen: an emit form with typed properties and the in-memory history of what
//  this app emitted. The SDK never echoes a custom event to the event listener, so the history is
//  the sample's own. It starts empty at each launch.
//

import Foundation
import Purchasely

class CustomEventsViewModel: ObservableObject {

    @Published var history: [EmittedCustomEvent] = []
    @Published var properties: [CustomEventProperty] = []
    @Published var lastMessage: String = ""

    /// `allowCampaigns` is the one public switch for campaigns: when on, an emitted event can
    /// trigger a campaign the Console attached to it.
    @Published var allowCampaigns: Bool = EnvironmentRepository.shared.isAllowCampaignsEnabled()

    func setAllowCampaigns(_ allow: Bool) {
        allowCampaigns = allow
        EnvironmentRepository.shared.setAllowCampaignsEnabled(allow)
        Purchasely.allowCampaigns(allow)
    }

    // MARK: - Emit

    /// Refuses an empty key or a value that is not of the chosen kind (`abc` as Int, `nan` or `1.5.2` as Double…): what
    /// the history shows must be exactly what the SDK received, never a substituted `0`. A Double typed with a
    /// comma is stored with a point, so the history shows the value the SDK got.
    @discardableResult
    func addProperty(key: String, kind: CustomEventProperty.Kind, rawValue: String) -> Bool {
        guard !key.isEmpty else { lastMessage = "A property needs a key."; return false }
        let raw = kind == .double ? CustomEventProperty.normalizedDecimal(rawValue) : rawValue
        let property = CustomEventProperty(key: key, kind: kind, rawValue: raw)
        guard property.value != nil else {
            lastMessage = "\"\(rawValue)\" is not a valid \(kind.rawValue) — property not added."
            return false
        }
        properties.removeAll { $0.key == key }
        properties.append(property)
        lastMessage = ""
        return true
    }

    func removeProperties(at offsets: IndexSet) {
        properties.remove(atOffsets: offsets)
    }

    /// `Purchasely.emit` as an integrator calls it. The name travels as typed, no trim, no case change, so
    /// the screen lets you see an undeclared or a mis-cased name being dropped.
    func emit(name: String) {
        guard !name.isEmpty else { lastMessage = "Give the event a name."; return }
        emit(name: name, properties: properties)
    }

    /// Emits a history line again: same name, same typed properties, a new `emit` (a new line, a new
    /// `event_created_at`). The form is left as it is.
    func retry(_ line: EmittedCustomEvent) {
        guard let properties = line.replayProperties else { return }
        emit(name: line.name, properties: properties)
    }

    private func emit(name: String, properties: [CustomEventProperty]) {
        var payload: [String: Any] = [:]
        for property in properties { if let value = property.value { payload[property.key] = value } }

        Purchasely.emit(name: name, properties: payload)

        let line = EmittedCustomEvent(name: name, properties: properties)
        history.insert(line, at: 0)

        lastMessage = "Emitted \"\(name)\". The SDK only forwards names the Console declares as custom events."
    }

    // MARK: - History

    func clearHistory() {
        history = []
    }
}
