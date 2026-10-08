//
//  SubscriptionsViewModel.swift
//  PurchaselySampleV2
//
//  Lists the current user's subscriptions via Purchasely.userSubscriptions() —
//  the way to verify a Web2App redemption attached a subscription (MOB-266).
//

import Foundation
import Purchasely

/// A flattened, display-ready view of a `PLYSubscription`. Enum values are mapped to readable
/// strings here (the SDK's own `.name`/`.string` helpers are internal), keeping the View simple.
struct SampleSubscriptionObject: Identifiable {
    let id = UUID()
    let productName: String
    let planName: String
    let status: String
    let source: String
    let environment: String
    let storeCountry: String?
    let purchasedAt: Date?
    let nextRenewalAt: Date?
    let cancelledAt: Date?
    let offerType: String
    let cumulatedRevenuesInUsd: Float
}

class SubscriptionsViewModel: ObservableObject {

    @Published var subscriptions: [SampleSubscriptionObject] = []
    @Published var viewState: ViewState = .loading
    @Published var toast: PLYToast? = nil

    init() {
        load()
    }

    /// - Parameter invalidateCache: `true` forces a fresh network fetch instead of the
    ///   local cache — use it via the "Refresh" button after a redemption completes.
    func load(invalidateCache: Bool = false) {
        viewState = .loading

        Purchasely.userSubscriptions(invalidateCache) { [weak self] subscriptions in
            guard let self else { return }
            DispatchQueue.main.async {
                self.subscriptions = (subscriptions ?? []).map(Self.map)
                self.viewState = .content
            }
        } failure: { [weak self] error in
            guard let self else { return }
            DispatchQueue.main.async {
                self.toast = PLYToast(type: .error, title: "Error",
                                      message: "Couldn't fetch subscriptions: \(error.localizedDescription)")
                self.viewState = .failure(error.localizedDescription)
            }
        }
    }

    private static func map(_ subscription: PLYSubscription) -> SampleSubscriptionObject {
        SampleSubscriptionObject(
            productName: subscription.product.name ?? subscription.product.vendorId,
            planName: subscription.plan.name ?? subscription.plan.vendorId,
            status: statusString(subscription.status),
            source: sourceString(subscription.subscriptionSource),
            environment: environmentString(subscription.environment),
            storeCountry: subscription.storeCountry,
            purchasedAt: subscription.purchasedDate,
            nextRenewalAt: subscription.nextRenewalDate,
            cancelledAt: subscription.cancelledDate,
            offerType: offerTypeString(subscription.offerType),
            cumulatedRevenuesInUsd: subscription.cumulatedRevenuesInUsd
        )
    }

    private static func statusString(_ status: PLYSubscriptionStatus) -> String {
        switch status {
        case .autoRenewing:         return "Auto-renewing"
        case .onHold:               return "On hold"
        case .inGracePeriod:        return "In grace period"
        case .autoRenewingCanceled: return "Canceled (active until renewal)"
        case .deactivated:          return "Deactivated"
        case .revoked:              return "Revoked"
        case .paused:               return "Paused"
        case .unpaid:               return "Unpaid"
        case .unknown:              return "Unknown"
        @unknown default:           return "Unknown"
        }
    }

    private static func sourceString(_ source: PLYSubscriptionSource) -> String {
        switch source {
        case .appleAppStore:      return "Apple App Store"
        case .googlePlayStore:    return "Google Play Store"
        case .amazonAppstore:     return "Amazon Appstore"
        case .huaweiAppGallery:   return "Huawei AppGallery"
        case .stripe:             return "Stripe"
        case .none:               return "Other / Web"
        // .invalidStringFormat is an internal decode sentinel (not visible here);
        // @unknown default catches it.
        @unknown default:         return "Unknown"
        }
    }

    private static func environmentString(_ environment: PLYSubscriptionEnvironment) -> String {
        switch environment {
        case .sandbox:    return "Sandbox"
        case .production: return "Production"
        case .unknown:    return "Unknown"
        @unknown default: return "Unknown"
        }
    }

    private static func offerTypeString(_ offerType: PLYSubscriptionOfferType) -> String {
        switch offerType {
        case .none:                return "None"
        case .freeTrial:           return "Free trial"
        case .introOffer:          return "Intro offer"
        case .promoCode:           return "Promo code"
        case .promotionalOffer:    return "Promotional offer"
        // .invalidStringFormat is an internal decode sentinel (not visible here).
        @unknown default:          return "Unknown"
        }
    }
}
