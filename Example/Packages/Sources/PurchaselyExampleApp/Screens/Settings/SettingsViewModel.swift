//
//  SettingsViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 19/12/2023.
//

import Foundation
import SwiftUI
import Purchasely

class SettingsViewModel: ObservableObject {

    // The config value types live in Core/SettingsConfig.swift.

    @Published var viewState: ViewState = .loading
    
    @Published var userId: String = ""
    @Published var presentationId: String = ""
    @Published var placementId: String = ""
    @Published var contentId: String = ""
    @Published var apiKey: String = ""
    
    @Published var observerMode: Bool = false
    @Published var asyncLoading: Bool = false
    @Published var storeKit2: Bool = true
    @Published var allowCampaigns: Bool = false
    
    @Published var selectedDisplayMethod: DisplayMethodCategory = .displayAsyncAwait
    @Published var selectedSourcePreference: SourceType = .auto
    @Published var selectedDisplayMode: DisplayMode = .modal
    @Published var selectedThemeMode: ThemeMode = .SYSTEM
    @Published var selectedLanguage: SampleLanguage = .system
    @Published var displayedBySample: Bool = false
    
    init() {
        self.viewState = .loading
        loadConfiguration()
        self.viewState = .content
    }
    
    var availableDisplayModes: [DisplayMode] {
        switch selectedDisplayMethod {
        case .displayAsyncAwait, .displayObjC, .fetchThenDisplay:
            return DisplayMode.sdkModes
        case .sampleApp:
            return DisplayMode.sampleAppModes
        }
    }

    var showsDisplayModePicker: Bool {
        switch selectedDisplayMethod {
        case .fetchThenDisplay:
            return false
        default:
            return true
        }
    }

    func clear() {
        loadConfiguration()
    }
    
    func loadConfiguration() {
        let config = getSettingsConfig()
        userId = config.userId ?? ""
        presentationId = config.presentationId  ?? ""
        placementId = config.placementId ?? ""
        contentId = config.contentId ?? ""
        apiKey = config.apiKey ?? ""
        observerMode = config.observerMode ?? false
        asyncLoading = config.asyncLoading ?? false
        storeKit2 = config.storeKit2 ?? true
        allowCampaigns = config.allowCampaigns ?? false
        selectedDisplayMethod = config.displayMethod
        selectedSourcePreference = config.sourcePreference
        selectedDisplayMode = config.displayMode
        selectedThemeMode = config.themeMode
        selectedLanguage = config.language
        displayedBySample = config.displayedBySample ?? false
    }
    
    func saveConfiguration(completion: @escaping () -> ()) {
        // Updating settings
        EnvironmentRepository.shared.setUserId(userId)
        EnvironmentRepository.shared.setPresentationId(presentationId)
        EnvironmentRepository.shared.setPlacementId(placementId)
        EnvironmentRepository.shared.setContentId(contentId)
        EnvironmentRepository.shared.setApiKey(apiKey)
        EnvironmentRepository.shared.setIsObserverModeEnabled(observerMode)
        EnvironmentRepository.shared.setAsyncLoading(asyncLoading)
        EnvironmentRepository.shared.setStorekit2Enabled(storeKit2)
        EnvironmentRepository.shared.setAllowCampaignsEnabled(allowCampaigns)
        EnvironmentRepository.shared.setDisplayMethod(selectedDisplayMethod)
        EnvironmentRepository.shared.setSourcePreference(selectedSourcePreference)
        EnvironmentRepository.shared.setDisplayMode(selectedDisplayMode)
        EnvironmentRepository.shared.setThemeMode(selectedThemeMode)
        EnvironmentRepository.shared.setSelectedLanguage(selectedLanguage)
        EnvironmentRepository.shared.setDisplayedBySample(displayedBySample)
        
        // Update SDK
        updateUserId()
        updateSdkSettings(completion)
        
        // Notify main view model
        NotificationCenter.default.post(name: Notification.Name("settingsUpdated"), object: nil)
    }
    
    private func updateUserId() {
        guard !userId.isEmpty else {
            Purchasely.userLogout()
            return
        }
        Purchasely.userLogin(with: userId) { (shouldRefreshCredentials) in
            // Refresh credentials
        }
    }
    
    private func updateSdkSettings(_ completion: @escaping () -> ()) {
        self.viewState = .loading
        
        let mode: Purchasely.PLYThemeMode = {
            switch self.selectedThemeMode {
            case .SYSTEM:
                return Purchasely.PLYThemeMode.system
            case .LIGHT:
                return Purchasely.PLYThemeMode.light
            case .DARK:
                return Purchasely.PLYThemeMode.dark
            }
        }()
        
        // Forces the SDK language (paywall content + error messages). Applied before `start()` so the
        // Accept-Language header is already right for the first fetch. `.system` passes nil, which
        // resets the SDK to the device language.
        EnvironmentRepository.shared.applySelectedLanguageToSDK()

        Purchasely
            .apiKey(EnvironmentRepository.shared.getApiKey())
            .runningMode(EnvironmentRepository.shared.isObserverModeEnabled() ? .observer : .full)
            .storekitSettings(EnvironmentRepository.shared.isStorekit2Enabled() ? .storeKit2 : .storeKit1)
            .logLevel(.debug)
            .themeMode(mode)
            .start { [self] error in
                self.viewState = error == nil ? .content : .failure(error?.localizedDescription)
                Purchasely.setDebugMode(enabled: true)
                Purchasely.allowCampaigns(EnvironmentRepository.shared.isAllowCampaignsEnabled())
                completion()
            }
    }

    private func getSettingsConfig() -> SettingsConfigObject {
        return SettingsConfigObject(userId: EnvironmentRepository.shared.getUserId(),
                                    presentationId: EnvironmentRepository.shared.getPresentationId(),
                                    placementId: EnvironmentRepository.shared.getPlacementId(),
                                    contentId: EnvironmentRepository.shared.getContentId(),
                                    apiKey: EnvironmentRepository.shared.getApiKey(),
                                    observerMode: EnvironmentRepository.shared.isObserverModeEnabled(),
                                    asyncLoading: EnvironmentRepository.shared.isAsyncLoading(),
                                    storeKit2: EnvironmentRepository.shared.isStorekit2Enabled(),
                                    allowCampaigns: EnvironmentRepository.shared.isAllowCampaignsEnabled(),
                                    displayMethod: EnvironmentRepository.shared.getDisplayMethod(),
                                    sourcePreference: EnvironmentRepository.shared.getSourcePreference(),
                                    displayMode: EnvironmentRepository.shared.getDisplayMode(),
                                    themeMode: EnvironmentRepository.shared.getThemeMode(),
                                    language: EnvironmentRepository.shared.getSelectedLanguage(),
                                    displayedBySample: EnvironmentRepository.shared.getDisplayedBySample())
    }
}

