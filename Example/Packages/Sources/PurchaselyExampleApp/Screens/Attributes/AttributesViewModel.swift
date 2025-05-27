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
        attributes = getAttributes().map {
            var type = ""
            switch $0.value {
            case is String:
                type =  Types.String.rawValue
            case is Bool:
                type =  Types.Bool.rawValue
            case is Date:
                type =  Types.Date.rawValue
            case is Double, is Float:
                type =  Types.Double.rawValue
            case is Int:
                type =  Types.Int.rawValue
            default:
                type = "Type unknown"
            }
            return AttributeObject(type: type, key: $0.key, value: $0.value) }
    }
    
    func getAttributes() -> [String:Any] {
        return Purchasely.userAttributes
    }
    
    func addNewAttribute(key: String, value: String) {
        attributes.append(AttributeObject(type: Types.String.rawValue, key: key, value: value))
        Purchasely.setUserAttribute(withStringValue: value, forKey: key)
    }
    
    func addNewAttribute(key: String, value: Int) {
        attributes.append(AttributeObject(type: Types.Int.rawValue, key: key, value: value))
        Purchasely.setUserAttribute(withIntValue: value, forKey: key)
    }
    
    func addNewAttribute(key: String, value: Bool) {
        attributes.append(AttributeObject(type: Types.Bool.rawValue, key: key, value: value))
        Purchasely.setUserAttribute(withBoolValue: value, forKey: key)
    }
    
    func addNewAttribute(key: String, value: Double) {
        attributes.append(AttributeObject(type: Types.Double.rawValue, key: key, value: value))
        Purchasely.setUserAttribute(withDoubleValue: value, forKey: key)
    }
    
    func addNewAttribute(key: String, value: Date) {
        attributes.append(AttributeObject(type: Types.Date.rawValue, key: key, value: value))
        Purchasely.setUserAttribute(withDateValue: value, forKey: key)
    }
    
    func addNewAttribute(key: String, value: [String]) {
        attributes.append(AttributeObject(type: Types.StringArray.rawValue, key: key, value: value))
        Purchasely.setUserAttribute(withStringArray: value, forKey: key)
    }
    
    func addNewAttribute(key: String, value: [Int]) {
        attributes.append(AttributeObject(type: Types.IntArray.rawValue, key: key, value: value))
        Purchasely.setUserAttribute(withIntArray: value, forKey: key)
    }
    
    func addNewAttribute(key: String, value: [Bool]) {
        attributes.append(AttributeObject(type: Types.BoolArray.rawValue, key: key, value: value))
        Purchasely.setUserAttribute(withBoolArray: value, forKey: key)
    }
    
    func addNewAttribute(key: String, value: [Double]) {
        attributes.append(AttributeObject(type: Types.DoubleArray.rawValue, key: key, value: value))
        Purchasely.setUserAttribute(withDoubleArray: value, forKey: key)
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
}
