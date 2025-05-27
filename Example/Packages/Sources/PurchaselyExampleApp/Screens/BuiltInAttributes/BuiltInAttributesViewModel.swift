//
//  BuiltInAttributesViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 31/05/2024.
//

import Foundation
import Purchasely

internal struct BuiltInAttributeElement: Hashable {
    var key: String
    var value: String
    
    var identifier: String {
        return UUID().uuidString
    }
    
    static func == (lhs: BuiltInAttributeElement, rhs: BuiltInAttributeElement) -> Bool {
        return lhs.key == rhs.key
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
}

class BuiltInAttributesViewModel: ObservableObject {
    @Published var attributes: [BuiltInAttributeElement] = []
    
    func clearBuiltInAttributes() {
        Purchasely.clearBuiltInAttributes()
        loadAttributes()
    }
    
    func loadAttributes() {
        let rawAttributes = Purchasely.getBuiltInAttributes()
        attributes.removeAll()
        for attr in rawAttributes {
            // Check if value is a non-empty dictionary
            if let dictValue = attr.value as? [String: Any], dictValue.isEmpty {
                continue // Skip empty dictionaries
            }
            
            attributes.append(BuiltInAttributeElement(key: attr.key, value: "\(attr.value)"))
        }
        attributes = attributes.sorted { $0.key < $1.key }
    }
}
