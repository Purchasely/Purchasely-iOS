//  SettingsConfig.swift
//
//  The sample's settings value types.
//  typealiases. Foundation only.

import Foundation

public enum DisplayMode: String, CaseIterable, Identifiable {
    case modal, fullscreen, push, drawer, popin

    public var displayName: String {
        switch self {
        case .modal: return "Modal"
        case .fullscreen: return "FullScreen"
        case .push: return "Push"
        case .drawer: return "Drawer (60%)"
        case .popin: return "Popin (70%)"
        }
    }

    /// Modes available when using SDK display APIs (async/await, completion)
    public static var sdkModes: [DisplayMode] { [.fullscreen, .modal, .drawer, .popin, .push] }
    /// Modes available when using Sample App (SwiftUI presentation)
    public static var sampleAppModes: [DisplayMode] { [.modal, .fullscreen, .push] }

    public var id: Self { self }
}

public enum ThemeMode: String, CaseIterable, Identifiable {
    case SYSTEM, LIGHT, DARK
    public var id: Self { self }
}

/// Locale forced on the SDK via `Purchasely.setLanguage(from:)`, which overrides the device language
/// for paywall content and SDK error messages.
///
/// Raw values are locale identifiers so they can be handed straight to `Locale(identifier:)`.
/// `system` maps to `nil`, the SDK's "follow the device" reset.
///
/// The SDK sends the resolved language as the `Accept-Language` header on every request, so a change
/// applies to the *next* paywall fetch — anything already fetched or preloaded keeps the language it
/// was fetched with. Region is preserved only for languages the backend advertises as regionalized
/// (see `acceptLanguageHeaderValue`); otherwise the bare language code is sent, so `pt-BR` may come
/// back as plain `pt` content.
public enum SampleLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case french = "fr"
    case spanish = "es"
    case german = "de"
    case italian = "it"
    case dutch = "nl"
    case portuguese = "pt"
    case portugueseBrazil = "pt-BR"
    case japanese = "ja"
    case korean = "ko"
    case chineseSimplified = "zh-Hans"

    public var id: Self { self }

    /// Value passed to `Purchasely.setLanguage(from:)`. `nil` restores the device language.
    public var locale: Locale? {
        self == .system ? nil : Locale(identifier: rawValue)
    }

    public var displayName: String {
        guard self != .system else { return "System" }
        // Name the language in English so the label stays readable whatever the device language is.
        let name = Locale(identifier: "en").localizedString(forIdentifier: rawValue) ?? rawValue
        return "\(name) (\(rawValue))"
    }
}

public struct SettingsConfigObject {
    public var userId: String?
    public var presentationId: String?
    public var placementId: String?
    public var contentId: String?
    public var apiKey: String?
    public var observerMode: Bool?
    public var asyncLoading: Bool?
    public var storeKit2: Bool?
    public var allowCampaigns: Bool?
    public var displayMethod: DisplayMethodCategory
    public var sourcePreference: SourceType
    public var displayMode: DisplayMode
    public var themeMode: ThemeMode
    public var language: SampleLanguage
    public var displayedBySample: Bool?

    public init(userId: String?, presentationId: String?, placementId: String?, contentId: String?,
                apiKey: String?,
                observerMode: Bool?, asyncLoading: Bool?, storeKit2: Bool?,
                allowCampaigns: Bool?, displayMethod: DisplayMethodCategory, sourcePreference: SourceType,
                displayMode: DisplayMode, themeMode: ThemeMode,
                language: SampleLanguage = .system,
                displayedBySample: Bool?) {
        self.userId = userId
        self.presentationId = presentationId
        self.placementId = placementId
        self.contentId = contentId
        self.apiKey = apiKey
        self.observerMode = observerMode
        self.asyncLoading = asyncLoading
        self.storeKit2 = storeKit2
        self.allowCampaigns = allowCampaigns
        self.displayMethod = displayMethod
        self.sourcePreference = sourcePreference
        self.displayMode = displayMode
        self.themeMode = themeMode
        self.language = language
        self.displayedBySample = displayedBySample
    }
}
