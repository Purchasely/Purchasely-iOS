//  CustomEventModels.swift
//
//  The Custom Events screen's value types: a property being typed in the form, and a line of the
//  in-memory history. Foundation only.

import Foundation

/// One property of the event being built, typed the way the SDK sanitizes it.
public struct CustomEventProperty: Identifiable, Hashable {
    public enum Kind: String, CaseIterable, Identifiable, Codable {
        case string = "String", int = "Int", double = "Double", bool = "Bool", date = "Date"
        public var id: Self { self }
    }

    public let id = UUID()
    public let key: String
    public let kind: Kind
    /// The value as typed; `value` converts it for the SDK.
    public let rawValue: String

    public init(key: String, kind: Kind, rawValue: String) {
        self.key = key
        self.kind = kind
        self.rawValue = rawValue
    }

    /// `nil` when the typed value is not one of its kind: the form refuses it rather than sending a substitute.
    /// `nan` and `inf` parse as a Double but the SDK drops a non-finite number, so they are refused too.
    public var value: Any? {
        switch kind {
        case .string: return rawValue
        case .int: return Int(rawValue)
        case .double: return Double(Self.normalizedDecimal(rawValue)).flatMap { $0.isFinite ? $0 : nil }
        case .bool: return rawValue == "true"
        case .date: return ISO8601DateFormatter().date(from: rawValue)
        }
    }

    public var display: String { "\(key) (\(kind.rawValue)) = \(rawValue)" }

    /// A French keyboard types `1,5`: both separators are a decimal point here.
    public static func normalizedDecimal(_ raw: String) -> String {
        raw.replacingOccurrences(of: ",", with: ".")
    }
}

/// One line of the in-memory history of emitted events.
public struct EmittedCustomEvent: Identifiable, Hashable, Codable {
    /// A property as typed, enough to emit the same event again.
    public struct TypedProperty: Hashable, Codable {
        public let key: String
        public let kind: CustomEventProperty.Kind
        public let rawValue: String
    }

    public let id: UUID
    public let name: String
    public let emittedAt: Date
    /// `key = value` lines, already rendered, for reading.
    public let properties: [String]
    /// What the retry button emits again.
    public let typedProperties: [TypedProperty]?

    public init(id: UUID = UUID(), name: String, emittedAt: Date = Date(), properties: [CustomEventProperty]) {
        self.id = id
        self.name = name
        self.emittedAt = emittedAt
        self.properties = properties.map { "\($0.key) = \($0.rawValue) (\($0.kind.rawValue))" }
        self.typedProperties = properties.map { TypedProperty(key: $0.key, kind: $0.kind, rawValue: $0.rawValue) }
    }

    /// The properties to emit again.
    public var replayProperties: [CustomEventProperty]? {
        typedProperties?.map { CustomEventProperty(key: $0.key, kind: $0.kind, rawValue: $0.rawValue) }
    }
}
