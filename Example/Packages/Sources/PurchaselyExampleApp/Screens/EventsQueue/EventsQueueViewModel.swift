//
//  EventsQueueViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 14/02/2024.
//

import Foundation
import Purchasely

struct Wrapper<T> : Codable where T : Codable {
    let wrapped : T
}

internal struct EventBatchElement: Hashable {
    var event: String
    var properties: [String: Any]
    
    var identifier: String {
        return UUID().uuidString
    }
    
    static func == (lhs: EventBatchElement, rhs: EventBatchElement) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
}

internal typealias EventBatch = [EventBatchElement]

class EventsQueueViewModel: ObservableObject {
    @Published var events: EventBatch = EventBatch()
    
    init() {
        refreshEvents()
    }
    
    func refreshEvents() {
        guard let decodedBatchData = try? JSONDecoder().decode(Wrapper<String>.self, from: UserDefaults.standard.object(forKey: "com.purchasely.pending.events") as! Data).wrapped.data(using: .utf8),
              let decodedBatch = try? JSONSerialization.jsonObject(with: decodedBatchData, options: []) as? [[String: Any]] else { return }
        
        var decodedEventsArray: EventBatch = [EventBatchElement]()
        
        for eventDict in decodedBatch {
            let event = EventBatchElement(event: eventDict["event"] as? String ?? "",
                                          properties: eventDict["properties"] as? [String: Any] ?? [:])
            decodedEventsArray.append(event)
        }
        
        self.events = decodedEventsArray
    }
}
