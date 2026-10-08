//
//  AttributesViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 19/12/2023.
//

import Foundation
import Purchasely

class AttributesViewModel: ObservableObject {
    
    enum Types: String, CaseIterable, Identifiable {
        case String, Bool, Int, Double, Date, StringArray, BoolArray, IntArray, DoubleArray
        var id: Self { self }
    }
    
    @Published var attributes: [AttributeObject] = []
    
    init() {
        reload()
    }

    /// Re-reads the attributes the SDK holds, so increments and clears show their real result.
    func reload() {
        attributes = getAttributes().map {
            // `Purchasely.userAttributes` hands back the concrete Swift value behind each
            // `AttributeValue` case, so an array never matches a scalar case and no array case
            // shadows another. The families are grouped only so they read apart.
            let type: String = switch $0.value {
            case is [Bool]:
                Types.BoolArray.rawValue
            case is [Int]:
                Types.IntArray.rawValue
            case is [Double], is [Float]:
                Types.DoubleArray.rawValue
            case is [String]:
                Types.StringArray.rawValue
            case is [Date]:
                // No public setter produces this, but `AttributeValue.init(from:)` turns a
                // `[String]` whose every element parses as a date into `.dateArray` — and a
                // redemption's `array_string` of timestamps does exactly that. Labelled rather
                // than shown as unknown.
                "\(Types.StringArray.rawValue) (dates)"
            case is String:
                Types.String.rawValue
            case is Bool:
                Types.Bool.rawValue
            case is Date:
                Types.Date.rawValue
            case is Double, is Float:
                Types.Double.rawValue
            case is Int:
                Types.Int.rawValue
            default:
                "Type unknown"
            }
            return AttributeObject(type: type, key: $0.key, value: $0.value, processingLegalBasis: nil)
        }
    }
    
    func getAttributes() -> [String:Any] {
        return Purchasely.userAttributes
    }
    
    func addNewAttribute(key: String, value: String, processingLegalBasis: PLYDataProcessingLegalBasis) {
        attributes.append(AttributeObject(type: Types.String.rawValue, key: key, value: value, processingLegalBasis: processingLegalBasis))
        Purchasely.setUserAttribute(withStringValue: value, forKey: key, processingLegalBasis: processingLegalBasis)
    }
    
    func addNewAttribute(key: String, value: Int, processingLegalBasis: PLYDataProcessingLegalBasis) {
        attributes.append(AttributeObject(type: Types.Int.rawValue, key: key, value: value, processingLegalBasis: processingLegalBasis))
        Purchasely.setUserAttribute(withIntValue: value, forKey: key, processingLegalBasis: processingLegalBasis)
    }
    
    func addNewAttribute(key: String, value: Bool, processingLegalBasis: PLYDataProcessingLegalBasis) {
        attributes.append(AttributeObject(type: Types.Bool.rawValue, key: key, value: value, processingLegalBasis: processingLegalBasis))
        Purchasely.setUserAttribute(withBoolValue: value, forKey: key, processingLegalBasis: processingLegalBasis)
    }
    
    func addNewAttribute(key: String, value: Double, processingLegalBasis: PLYDataProcessingLegalBasis) {
        attributes.append(AttributeObject(type: Types.Double.rawValue, key: key, value: value, processingLegalBasis: processingLegalBasis))
        Purchasely.setUserAttribute(withDoubleValue: value, forKey: key, processingLegalBasis: processingLegalBasis)
    }
    
    func addNewAttribute(key: String, value: Date, processingLegalBasis: PLYDataProcessingLegalBasis) {
        attributes.append(AttributeObject(type: Types.Date.rawValue, key: key, value: value, processingLegalBasis: processingLegalBasis))
        Purchasely.setUserAttribute(withDateValue: value, forKey: key, processingLegalBasis: processingLegalBasis)
    }
    
    func addNewAttribute(key: String, value: [String], processingLegalBasis: PLYDataProcessingLegalBasis) {
        attributes.append(AttributeObject(type: Types.StringArray.rawValue, key: key, value: value, processingLegalBasis: processingLegalBasis))
        Purchasely.setUserAttribute(withStringArray: value, forKey: key, processingLegalBasis: processingLegalBasis)
    }
    
    func addNewAttribute(key: String, value: [Int], processingLegalBasis: PLYDataProcessingLegalBasis) {
        attributes.append(AttributeObject(type: Types.IntArray.rawValue, key: key, value: value, processingLegalBasis: processingLegalBasis))
        Purchasely.setUserAttribute(withIntArray: value, forKey: key, processingLegalBasis: processingLegalBasis)
    }
    
    func addNewAttribute(key: String, value: [Bool], processingLegalBasis: PLYDataProcessingLegalBasis) {
        attributes.append(AttributeObject(type: Types.BoolArray.rawValue, key: key, value: value, processingLegalBasis: processingLegalBasis))
        Purchasely.setUserAttribute(withBoolArray: value, forKey: key, processingLegalBasis: processingLegalBasis)
    }
    
    func addNewAttribute(key: String, value: [Double], processingLegalBasis: PLYDataProcessingLegalBasis) {
        attributes.append(AttributeObject(type: Types.DoubleArray.rawValue, key: key, value: value, processingLegalBasis: processingLegalBasis))
        Purchasely.setUserAttribute(withDoubleArray: value, forKey: key, processingLegalBasis: processingLegalBasis)
    }
    
    func increment(key: String, by value: Int, processingLegalBasis: PLYDataProcessingLegalBasis) {
        Purchasely.incrementUserAttribute(withKey: key, value: value, processingLegalBasis: processingLegalBasis)
        reload()
    }

    func decrement(key: String, by value: Int, processingLegalBasis: PLYDataProcessingLegalBasis) {
        Purchasely.decrementUserAttribute(withKey: key, value: value, processingLegalBasis: processingLegalBasis)
        reload()
    }

    func clearAll() {
        Purchasely.clearUserAttributes()
        reload()
    }

    func removeAttribute(key: String) {
        Purchasely.clearUserAttribute(forKey: key)
    }
    
    func removeAttribute(index: IndexSet?) {
        guard let index = index, let indexInt = index.first else { return }
        let attributeToRemove = attributes[indexInt]
        Purchasely.clearUserAttribute(forKey: attributeToRemove.key)
        attributes.remove(atOffsets: index)
    }
}

struct AttributeObject: Hashable {
    
    static func == (lhs: AttributeObject, rhs: AttributeObject) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    var identifier: String {
        return UUID().uuidString
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    var type: String
    var key: String
    var value: Any
    
    var processingLegalBasis: PLYDataProcessingLegalBasis?
}
