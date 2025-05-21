//
//  EnvironmentRepository.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 13/12/2023.
//

import Foundation
import Purchasely

class EnvironmentRepository {
    
    public static let shared: EnvironmentRepository = EnvironmentRepository()
    
    public static let BASE_API_KEY: String = "fcb39be4-2ba4-4db7-bde3-2a5a1e20745d"
    
    private init() { }
    
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
            return UserDefaults.standard.string(forKey: EnvironmentRepository.API_KEY)!
        }
    }
    
    public func setApiKey(_ apiKey: String?) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            self.setApiKey(EnvironmentRepository.BASE_API_KEY)
            return
        }
        UserDefaults.standard.setValue(apiKey, forKey: EnvironmentRepository.API_KEY)
    }
    
    public func isObserverModeEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: EnvironmentRepository.OBSERVER_MODE_ENABLED)
    }
    
    public func setIsObserverModeEnabled(_ enabled: Bool) {
        UserDefaults.standard.setValue(enabled, forKey: EnvironmentRepository.OBSERVER_MODE_ENABLED)
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
    
    public func getApiUrl() -> String? {
        return UserDefaults.standard.string(forKey: EnvironmentRepository.API_URL)
    }
    
    public func setApiUrl(_ apiUrl: String) {
        UserDefaults.standard.setValue(apiUrl.isEmpty ? nil : apiUrl, forKey: EnvironmentRepository.API_URL)
    }
    
    public func getPresentationUrl() -> String? {
        return UserDefaults.standard.string(forKey: EnvironmentRepository.PRESENTATION_URL)
    }
    
    public func setPresentationUrl(_ presentationUrl: String) {
        UserDefaults.standard.setValue(presentationUrl, forKey: EnvironmentRepository.PRESENTATION_URL)
    }
    
    public func isAsyncLoading() -> Bool {
        return UserDefaults.standard.bool(forKey: EnvironmentRepository.ASYNC_LOADING)
    }
    
    public func setAsyncLoading(_ enabled: Bool) {
        UserDefaults.standard.setValue(enabled, forKey: EnvironmentRepository.ASYNC_LOADING)
    }
    
    public func getDisplayMode() -> SettingsViewModel.DisplayMode {
        if let displayMode = UserDefaults.standard.string(forKey: EnvironmentRepository.DISPLAY_MODE) {
            return SettingsViewModel.DisplayMode(rawValue: displayMode) ?? .modal
        }
        setDisplayMode(.modal)
        return SettingsViewModel.DisplayMode.modal
    }
    
    public func setDisplayMode(_ displayMode: SettingsViewModel.DisplayMode) {
        UserDefaults.standard.setValue(displayMode.rawValue, forKey: EnvironmentRepository.DISPLAY_MODE)
    }
    
    public func getThemeMode() -> SettingsViewModel.ThemeMode {
        if let themeMode = UserDefaults.standard.string(forKey: EnvironmentRepository.THEME_MODE) {
            return SettingsViewModel.ThemeMode(rawValue: themeMode) ?? .SYSTEM
        }
        setThemeMode(.SYSTEM)
        return SettingsViewModel.ThemeMode.SYSTEM
    }
    
    public func setThemeMode(_ mode: SettingsViewModel.ThemeMode) {
        UserDefaults.standard.setValue(mode.rawValue, forKey: EnvironmentRepository.THEME_MODE)
    }
}

extension EnvironmentRepository {
    fileprivate static let ENVIRONMENT_PROD = "ENVIRONMENT_PROD"
    fileprivate static let ALREADY_LAUNCHED = "ALREADY_LAUNCHED"
    fileprivate static let STOREKIT2_ENABLED = "STOREKIT2_ENABLED"
    fileprivate static let OBSERVER_MODE_ENABLED = "OBSERVER_MODE_ENABLED"
    fileprivate static let API_KEY = "API_KEY"
    fileprivate static let USER_ID = "USER_ID"
    fileprivate static let IS_TEST_RUN = "IS_TEST_RUN"
    fileprivate static let PRESENTATION_ID = "PRESENTATION_ID"
    fileprivate static let PLACEMENT_ID = "PLACEMENT_ID"
    fileprivate static let PRODUCT_ID = "PRODUCT_ID"
    fileprivate static let CONTENT_ID = "CONTENT_ID"
    fileprivate static let API_URL = "API_URL"
    fileprivate static let PRESENTATION_URL = "PRESENTATION_URL"
    fileprivate static let ASYNC_LOADING = "ASYNC_LOADING"
    fileprivate static let DISPLAY_MODE = "DISPLAY_MODE"
    fileprivate static let SELECTED_TEMPLATE = "SELECTED_TEMPLATE"
    fileprivate static let THEME_MODE = "THEME_MODE"
}
