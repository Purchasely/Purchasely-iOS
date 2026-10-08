//  AppRoute.swift
//
//  The navigable destinations of the sample. Pure data (Foundation only).

import Foundation

public enum AppRoute: Hashable, Sendable {
    case settings
    case products
    case subscriptions
    case attributes
    case builtInAttributes
    case deeplinks
    case directPurchase
    case dynamicOfferings
    /// The "SDK events" screen: events the SDK reports to the event delegate.
    case eventsQueue
    /// The Custom Events screen: an emit form and the in-memory history of emitted events.
    case customEvents
    case privacy
    case logs
}
