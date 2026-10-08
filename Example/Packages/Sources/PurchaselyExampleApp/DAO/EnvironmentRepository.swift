//
//  EnvironmentRepository.swift
//  PurchaselySampleV2
//
//  UserDefaults-backed store for the sample's settings.
//

import Foundation
import Purchasely

final class EnvironmentRepository {

    public static let shared: EnvironmentRepository = EnvironmentRepository()

    public static let BASE_API_KEY: String = "fcb39be4-2ba4-4db7-bde3-2a5a1e20745d"

    private init() { }

    public func getDisplayedBySample() -> Bool {
        return UserDefaults.standard.bool(forKey: EnvironmentRepository.DISPLAYED_BY_SAMPLE)
    }

    public func setDisplayedBySample(_ displayedBySample: Bool) {
        UserDefaults.standard.setValue(displayedBySample, forKey: EnvironmentRepository.DISPLAYED_BY_SAMPLE)
    }

    public func getPurchaselySDKVersion() -> String {
        return Purchasely.getSDKVersion() ?? "-"
    }

    public func isAppAlreadyLaunched() -> Bool {
        return UserDefaults.standard.bool(forKey: EnvironmentRepository.ALREADY_LAUNCHED)
    }

    public func setAppAlreadyLaunched(_ alreadyLaunched: Bool) {
        UserDefaults.standard.setValue(alreadyLaunched, forKey: EnvironmentRepository.ALREADY_LAUNCHED)
    }

    public func isStorekit2Enabled() -> Bool {
        return UserDefaults.standard.bool(forKey: EnvironmentRepository.STOREKIT2_ENABLED)
    }

    public func setStorekit2Enabled(_ enabled: Bool) {
        UserDefaults.standard.setValue(enabled, forKey: EnvironmentRepository.STOREKIT2_ENABLED)
    }

    public func getApiKey() -> String {
        if let apiKey = UserDefaults.standard.string(forKey: EnvironmentRepository.API_KEY),
           !apiKey.isEmpty {
            return apiKey
        } else {
            self.setApiKey(EnvironmentRepository.BASE_API_KEY)
            return EnvironmentRepository.BASE_API_KEY
        }
    }

    public func setApiKey(_ apiKey: String?) {
        // non-nil & non-empty -> use it; otherwise fall back to the default (no recursion).
        let resolved = apiKey.flatMap { $0.isEmpty ? nil : $0 } ?? EnvironmentRepository.BASE_API_KEY
        UserDefaults.standard.setValue(resolved, forKey: EnvironmentRepository.API_KEY)
    }

    public func isObserverModeEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: EnvironmentRepository.OBSERVER_MODE_ENABLED)
    }

    public func setIsObserverModeEnabled(_ enabled: Bool) {
        UserDefaults.standard.setValue(enabled, forKey: EnvironmentRepository.OBSERVER_MODE_ENABLED)
    }

    public func isAllowCampaignsEnabled() -> Bool {
        // On by default, like the Android sample: the key is absent until the switch is used.
        return UserDefaults.standard.object(forKey: EnvironmentRepository.ALLOW_CAMPAIGNS_ENABLED) as? Bool ?? true
    }

    public func setAllowCampaignsEnabled(_ enabled: Bool) {
        UserDefaults.standard.setValue(enabled, forKey: EnvironmentRepository.ALLOW_CAMPAIGNS_ENABLED)
    }

    public func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: EnvironmentRepository.USER_ID)
    }

    public func setUserId(_ userId: String) {
        UserDefaults.standard.setValue(userId, forKey: EnvironmentRepository.USER_ID)
    }

    public func getPresentationId() -> String? {
        return UserDefaults.standard.string(forKey: EnvironmentRepository.PRESENTATION_ID)
    }

    public func setPresentationId(_ presentationId: String) {
        UserDefaults.standard.setValue(presentationId.isEmpty ? nil : presentationId, forKey: EnvironmentRepository.PRESENTATION_ID)
    }

    public func getPlacementId() -> String? {
        return UserDefaults.standard.string(forKey: EnvironmentRepository.PLACEMENT_ID)
    }

    public func setPlacementId(_ placementId: String) {
        UserDefaults.standard.setValue(placementId.isEmpty ? nil : placementId, forKey: EnvironmentRepository.PLACEMENT_ID)
    }

    public func getProductId() -> String? {
        return UserDefaults.standard.string(forKey: EnvironmentRepository.PRODUCT_ID)
    }

    public func setProductId(_ productId: String) {
        UserDefaults.standard.setValue(productId.isEmpty ? nil : productId, forKey: EnvironmentRepository.PRODUCT_ID)
    }

    public func getContentId() -> String? {
        return UserDefaults.standard.string(forKey: EnvironmentRepository.CONTENT_ID)
    }

    public func setContentId(_ contentId: String) {
        UserDefaults.standard.setValue(contentId.isEmpty ? nil : contentId, forKey: EnvironmentRepository.CONTENT_ID)
    }

    public func isAsyncLoading() -> Bool {
        return UserDefaults.standard.bool(forKey: EnvironmentRepository.ASYNC_LOADING)
    }

    public func setAsyncLoading(_ enabled: Bool) {
        UserDefaults.standard.setValue(enabled, forKey: EnvironmentRepository.ASYNC_LOADING)
    }

    public func getDisplayMethod() -> DisplayMethodCategory {
        if let method = UserDefaults.standard.string(forKey: EnvironmentRepository.DISPLAY_METHOD) {
            return DisplayMethodCategory(rawValue: method) ?? .displayAsyncAwait
        }
        setDisplayMethod(.displayAsyncAwait)
        return .displayAsyncAwait
    }

    public func setDisplayMethod(_ method: DisplayMethodCategory) {
        UserDefaults.standard.setValue(method.rawValue, forKey: EnvironmentRepository.DISPLAY_METHOD)
    }

    public func getSourcePreference() -> SourceType {
        if let source = UserDefaults.standard.string(forKey: EnvironmentRepository.SOURCE_PREFERENCE) {
            return SourceType(rawValue: source) ?? .auto
        }
        setSourcePreference(.auto)
        return .auto
    }

    public func setSourcePreference(_ source: SourceType) {
        UserDefaults.standard.setValue(source.rawValue, forKey: EnvironmentRepository.SOURCE_PREFERENCE)
    }

    public func getDisplayMode() -> DisplayMode {
        if let displayMode = UserDefaults.standard.string(forKey: EnvironmentRepository.DISPLAY_MODE) {
            return DisplayMode(rawValue: displayMode) ?? .modal
        }
        setDisplayMode(.modal)
        return DisplayMode.modal
    }

    public func setDisplayMode(_ displayMode: DisplayMode) {
        UserDefaults.standard.setValue(displayMode.rawValue, forKey: EnvironmentRepository.DISPLAY_MODE)
    }

    public func getThemeMode() -> ThemeMode {
        if let themeMode = UserDefaults.standard.string(forKey: EnvironmentRepository.THEME_MODE) {
            return ThemeMode(rawValue: themeMode) ?? .SYSTEM
        }
        setThemeMode(.SYSTEM)
        return ThemeMode.SYSTEM
    }

    public func setThemeMode(_ mode: ThemeMode) {
        UserDefaults.standard.setValue(mode.rawValue, forKey: EnvironmentRepository.THEME_MODE)
    }

    public func getSelectedLanguage() -> SampleLanguage {
        if let language = UserDefaults.standard.string(forKey: EnvironmentRepository.SELECTED_LANGUAGE) {
            return SampleLanguage(rawValue: language) ?? .system
        }
        setSelectedLanguage(.system)
        return SampleLanguage.system
    }

    public func setSelectedLanguage(_ language: SampleLanguage) {
        UserDefaults.standard.setValue(language.rawValue, forKey: EnvironmentRepository.SELECTED_LANGUAGE)
    }

    /// Pushes the persisted language into the SDK. Called both when settings are saved and before
    /// `start()` on launch, so a forced language survives a relaunch.
    public func applySelectedLanguageToSDK() {
        Purchasely.setLanguage(from: getSelectedLanguage().locale)
    }
}

extension EnvironmentRepository {
    fileprivate static let ALREADY_LAUNCHED = "ALREADY_LAUNCHED"
    fileprivate static let STOREKIT2_ENABLED = "STOREKIT2_ENABLED"
    fileprivate static let OBSERVER_MODE_ENABLED = "OBSERVER_MODE_ENABLED"
    fileprivate static let ALLOW_CAMPAIGNS_ENABLED = "ALLOW_CAMPAIGNS_ENABLED"
    fileprivate static let API_KEY = "API_KEY"
    fileprivate static let USER_ID = "USER_ID"
    fileprivate static let PRESENTATION_ID = "PRESENTATION_ID"
    fileprivate static let PLACEMENT_ID = "PLACEMENT_ID"
    fileprivate static let PRODUCT_ID = "PRODUCT_ID"
    fileprivate static let CONTENT_ID = "CONTENT_ID"
    fileprivate static let ASYNC_LOADING = "ASYNC_LOADING"
    fileprivate static let DISPLAY_METHOD = "DISPLAY_METHOD"
    fileprivate static let SOURCE_PREFERENCE = "SOURCE_PREFERENCE"
    fileprivate static let DISPLAY_MODE = "DISPLAY_MODE"
    fileprivate static let THEME_MODE = "THEME_MODE"
    fileprivate static let SELECTED_LANGUAGE = "SELECTED_LANGUAGE"
    fileprivate static let DISPLAYED_BY_SAMPLE = "DISPLAYED_BY_SAMPLE"
}
