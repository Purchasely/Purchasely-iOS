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
    
    enum DisplayMode: String, CaseIterable, Identifiable {
        case modal, fullscreen, push
        var id: Self { self }
    }
    
    enum ThemeMode: String, CaseIterable, Identifiable {
        case SYSTEM, LIGHT, DARK
        var id: Self { self }
    }
    
    @Published var viewState: ViewState = .loading
    
    @Published var userId: String = ""
    @Published var presentationId: String = ""
    @Published var placementId: String = ""
    @Published var contentId: String = ""
    @Published var apiKey: String = ""
    
    @Published var observerMode: Bool = false
    @Published var asyncLoading: Bool = false
    @Published var storeKit2: Bool = true
    
    @Published var selectedDisplayMode: DisplayMode = .modal
    @Published var selectedThemeMode: ThemeMode = .SYSTEM
    
    init() {
        self.viewState = .loading
        loadConfiguration()
        self.viewState = .content
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
        selectedDisplayMode = config.displayMode
        selectedThemeMode = config.themeMode
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
        EnvironmentRepository.shared.setDisplayMode(selectedDisplayMode)
        EnvironmentRepository.shared.setThemeMode(selectedThemeMode)
        
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
        
        Purchasely.setThemeMode(mode)

        Purchasely.start(withAPIKey: EnvironmentRepository.shared.getApiKey(),
                         runningMode: EnvironmentRepository.shared.isObserverModeEnabled() ? .paywallObserver : .full,
                         storekitSettings: EnvironmentRepository.shared.isStorekit2Enabled() ? .storeKit2 : .storeKit1,
                         logLevel: .debug) { [self] (success, error) in
            self.viewState = success ? .content : .failure(error?.localizedDescription)
            completion()
        }
    }
    
    private func getSettingsConfig() -> SettingsConfigObject {
        return SettingsConfigObject(userId: EnvironmentRepository.shared.getUserId(),
                                    presentationId: EnvironmentRepository.shared.getPresentationId(),
                                    placementId: EnvironmentRepository.shared.getPlacementId(),
                                    contentId: EnvironmentRepository.shared.getContentId(),
                                    apiKey: EnvironmentRepository.shared.getApiKey(),
                                    apiUrl: EnvironmentRepository.shared.getApiUrl(),
                                    observerMode: EnvironmentRepository.shared.isObserverModeEnabled(),
                                    asyncLoading: EnvironmentRepository.shared.isAsyncLoading(),
                                    storeKit2: EnvironmentRepository.shared.isStorekit2Enabled(),
                                    displayMode: EnvironmentRepository.shared.getDisplayMode(),
                                    themeMode: EnvironmentRepository.shared.getThemeMode())
    }
}

struct SettingsConfigObject {
    var userId: String?
    var presentationId: String?
    var placementId: String?
    var contentId: String?
    var apiKey: String?
    var apiUrl: String?
    var observerMode: Bool?
    var asyncLoading: Bool?
    var storeKit2: Bool?
    var displayMode: SettingsViewModel.DisplayMode
    var themeMode: SettingsViewModel.ThemeMode
}
