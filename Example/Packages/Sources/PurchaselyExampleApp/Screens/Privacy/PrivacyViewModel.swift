import Purchasely
import SwiftUI

final class PrivacyViewModel: ObservableObject {

    enum PrivacyFeature: String, CaseIterable, Codable, Equatable, Hashable, Identifiable {
        case allNonEssentials
        case analytics
        case identifiedAnalytics
        case campaigns
        case personalization
        case thirdPartyIntegrations
        case refundHandling
        
        var id: String { rawValue }
        
        var sdkFeature: PLYDataProcessingPurpose {
            switch self {
            case .allNonEssentials: .allNonEssentials
            case .analytics: .analytics
            case .identifiedAnalytics: .identifiedAnalytics
            case .campaigns: .campaigns
            case .personalization: .personalization
            case .thirdPartyIntegrations: .thirdPartyIntegrations
            case .refundHandling: .refundHandling
            }
        }
    }
    
    struct PrivacyFeatureViewModel: Codable, Equatable, Hashable, Identifiable {
        let feature: PrivacyFeature
        let consentGranted: Bool
        
        var id: PrivacyFeature { feature }
    }
    
    static var privacyFeaturesStore: [PrivacyFeatureViewModel] {
        get {
            guard let data = UserDefaults.standard.object(forKey: "privacyFeaturesStore") as? Data else {
                return []
            }
            return (try? JSONDecoder().decode([PrivacyFeatureViewModel].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            UserDefaults.standard.set(data, forKey:  "privacyFeaturesStore")
        }
    }

    @Published var privacyFeatures: [PrivacyFeatureViewModel] = privacyFeaturesStore
    
    init() {
        let stored = Self.privacyFeaturesStore
        if stored.isEmpty {
            Purchasely.revokeDataProcessingConsent(for: [])
        }
        // A feature added after the store was written shows up granted.
        privacyFeatures = PrivacyFeature.allCases.map { feature in
            stored.first { $0.feature == feature } ?? PrivacyFeatureViewModel(feature: feature, consentGranted: true)
        }
    }

    func associatedFeaturesToGrant(with feature: PrivacyFeature) -> Set<PrivacyFeature> {
        switch feature {
        case .allNonEssentials: [.allNonEssentials, .analytics, .identifiedAnalytics, .campaigns, .personalization, .thirdPartyIntegrations]
        case .analytics: [.allNonEssentials,.analytics]
        case .identifiedAnalytics: [.allNonEssentials, .analytics, .identifiedAnalytics]
        case .campaigns: [.allNonEssentials, .campaigns]
        case .personalization: [.allNonEssentials, .personalization]
        case .thirdPartyIntegrations: [.allNonEssentials, .thirdPartyIntegrations]
        case .refundHandling: [.refundHandling]
        }
    }
    
    func associatedFeaturesToRevoke(with feature: PrivacyFeature) -> Set<PrivacyFeature> {
        switch feature {
        case .allNonEssentials: [.allNonEssentials, .analytics, .identifiedAnalytics, .campaigns, .personalization, .thirdPartyIntegrations]
        case .analytics: [.analytics, .identifiedAnalytics]
        case .identifiedAnalytics: [.identifiedAnalytics]
        case .campaigns: [.campaigns]
        case .personalization: [.personalization]
        case .thirdPartyIntegrations: [.thirdPartyIntegrations]
        case .refundHandling: [.refundHandling]
        }
    }

    func grantConsentForFeature(_ feature: PrivacyFeature) {
        let updatedFeatures = associatedFeaturesToGrant(with: feature)
            .map { PrivacyFeatureViewModel(feature: $0, consentGranted: true) }
        
        for updatedFeature in updatedFeatures {
            if let index = privacyFeatures.firstIndex(where: { $0.feature == updatedFeature.feature }) {
                privacyFeatures[index] = updatedFeature
            } else {
                privacyFeatures.append(updatedFeature)
            }
        }

        Self.privacyFeaturesStore = privacyFeatures
        Purchasely.revokeDataProcessingConsent(for: Set(privacyFeatures.filter { !$0.consentGranted }.map(\.feature.sdkFeature)))
    }
    
    func revokeConsentForFeature(_ feature: PrivacyFeature) {
        let updatedFeatures = associatedFeaturesToRevoke(with: feature)
            .map { PrivacyFeatureViewModel(feature: $0, consentGranted: false) }

        for updatedFeature in updatedFeatures {
            if let index = privacyFeatures.firstIndex(where: { $0.feature == updatedFeature.feature }) {
                privacyFeatures[index] = updatedFeature
            } else {
                privacyFeatures.append(updatedFeature)
            }
        }
        
        let nonEssentials = associatedFeaturesToRevoke(with: .allNonEssentials).subtracting([.allNonEssentials])
        let anyNonEssentialGranted = privacyFeatures.contains { nonEssentials.contains($0.feature) && $0.consentGranted }
        if !anyNonEssentialGranted, let index = privacyFeatures.firstIndex(where: { $0.feature == .allNonEssentials }) {
            privacyFeatures[index] = PrivacyFeatureViewModel(feature: .allNonEssentials, consentGranted: false)
        }

        Self.privacyFeaturesStore = privacyFeatures
        Purchasely.revokeDataProcessingConsent(for: Set(privacyFeatures.filter { !$0.consentGranted }.map(\.feature.sdkFeature)))
    }
}
