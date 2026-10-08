//
//  PresentationViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 21/12/2023.
//

import Foundation
import SwiftUI
import Purchasely
import StoreKit

/// What the SDK reports about the presentation it served: which placement, audience, A/B test,
/// campaign and flow produced it.
struct PresentationInfo {
    let rows: [(String, String)]

    init(_ presentation: PLYPresentation) {
        func text(_ value: String?) -> String { value ?? "-" }
        rows = [
            ("type", String(describing: presentation.type)),
            ("placementId", text(presentation.placementId)),
            ("audienceId", text(presentation.audienceId)),
            ("abTestId", text(presentation.abTestId)),
            ("campaignId", text(presentation.campaignId)),
            ("flowId", text(presentation.flowId)),
        ]
    }
}

class PresentationContainerViewModel: ObservableObject {
    
    @Published var viewState: ViewState = .loading
    @Published var paywallView: PLYPresentationView?
    @Published var isAsyncLoading: Bool = false
    
    /// Metadata of the loaded presentation, shown in the info card.
    @Published var info: PresentationInfo?

    var productRequestDelegate: ProductRequestDelegate?
    var controller: UIViewController?
    
    init() {
        isAsyncLoading = EnvironmentRepository.shared.isAsyncLoading()
    }

    
    func loadCurrentPresentation() {

        self.viewState = .loading
        let paywallIdentifier = EnvironmentRepository.shared.getPresentationId()
        let contentId = EnvironmentRepository.shared.getContentId()

        setupActionInterceptors()

        let builder: PLYPresentationBuilder
        if let placementId = EnvironmentRepository.shared.getPlacementId() {
            builder = PLYPresentationBuilder.forPlacementId(placementId)
        } else if let paywallIdentifier, !paywallIdentifier.isEmpty {
            builder = PLYPresentationBuilder.forScreenId(paywallIdentifier)
        } else {
            builder = PLYPresentationBuilder.default()
        }
        if let contentId { _ = builder.contentId(contentId) }
        let request = builder
            .onDismissed { outcome in
                Self.logDismiss(outcome)
            }
            .build()

        preloadPresentation(request)
    }

    func loadPresentation(paywallIdentifier: String) {
        self.viewState = .loading
        EnvironmentRepository.shared.setPresentationId(paywallIdentifier)
        preloadPresentation(
            PLYPresentationBuilder.forScreenId(paywallIdentifier).build()
        )
    }

    private func preloadPresentation(_ request: PLYPresentationRequest) {
        Task { @MainActor [weak self] in
            do {
                let presentation = try await request.preload()
                guard let paywallView = presentation.swiftUIView else {
                    self?.viewState = .failure("No SwiftUI view available for presentation")
                    return
                }
                self?.paywallView = paywallView
                self?.info = PresentationInfo(presentation)
                self?.viewState = .content
            } catch {
                self?.viewState = .failure("Error while prefetching presentation: \(error.localizedDescription)")
            }
        }
    }

    private static func logDismiss(_ outcome: PLYPresentationOutcome) {
        switch outcome.purchaseResult {
        case .purchased:
            SampleLogger.shared.addLog(message: "[onDismissed] PURCHASED")
        case .restored:
            SampleLogger.shared.addLog(message: "[onDismissed] RESTORED")
        case .cancelled:
            SampleLogger.shared.addLog(message: "[onDismissed] CANCELLED")
        case .none:
            SampleLogger.shared.addLog(message: "[onDismissed] NO PURCHASE")
        @unknown default:
            SampleLogger.shared.addLog(message: "[onDismissed] UNKNOWN")
        }
    }
    
    private func setupActionInterceptors() {
        let observerMode = EnvironmentRepository.shared.isObserverModeEnabled()
        let storekit2Enabled = EnvironmentRepository.shared.isStorekit2Enabled()

        // Intercept the tap on login
        Purchasely.interceptAction(.login) { info, params, completion in
            // When the user has completed the process
            // Pass .notHandled to let the SDK reload the paywall or dismiss if user already has an active subscription
            completion(.notHandled)
        }

        Purchasely.interceptAction(.close) { info, params, completion in
            completion(.notHandled)
        }

        Purchasely.interceptAction(.navigate) { info, params, completion in
            completion(.notHandled)
        }

        Purchasely.interceptAction(.purchase) { [weak self] info, params, completion in
            guard let self else {
                completion(.failed)
                return
            }
            guard let plan = params?.plan,
                  let appleProductId = plan.appleProductId else {
                      completion(.success)
                      return
                  }

            if observerMode {
                if storekit2Enabled, #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    self.storeKit2PurchaseProcess(appleProductId: appleProductId,
                                                  promoOffer: params?.promoOffer,
                                                  interceptorInfo: info,
                                                  completion: completion)
                } else {
                    self.storeKit1PurchaseProcess(appleProductId: appleProductId, interceptorInfo: info, completion: completion)
                }
            } else {
                completion(.notHandled)
            }
        }

        Purchasely.interceptAction(.closeAll) { info, params, completion in
            completion(.notHandled)
        }
    }
    
    private func storeKit1PurchaseProcess(appleProductId: String, interceptorInfo: PLYInterceptorInfo?, completion: @escaping (PLYInterceptResult) -> Void) {
        let request = SKProductsRequest(productIdentifiers: Set<String>([appleProductId]))
        productRequestDelegate = ProductRequestDelegate()
        productRequestDelegate?.completion = completion
        request.delegate = productRequestDelegate // Get Product in the `productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse)` method
        request.start()
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private func storeKit2PurchaseProcess(appleProductId: String,
                                          promoOffer: PLYPromoOffer?,
                                          interceptorInfo: PLYInterceptorInfo?,
                                          completion: @escaping (PLYInterceptResult) -> Void) {
        Task { [weak self] in
            guard let `self` = self else {
                DispatchQueue.main.async { completion(.failed) }
                return
            }
            SampleLogger.shared.addLog(message: "[StoreKit2][Observer Mode] Purchasing \(appleProductId)")
            let purchased: Bool
            do {
                purchased = try await self.purchaseWithStoreKit2(for:appleProductId,
                                                                 with: promoOffer?.storeOfferId,
                                                                 interceptorInfo: interceptorInfo,
                                                                 completion: completion)
            } catch {
                // The purchase never reached a result: tell the SDK, exactly once.
                SampleLogger.shared.addLog(message: "[StoreKit2][Observer Mode] error with purchasing with StoreKit2: \(error)")
                DispatchQueue.main.async { completion(.failed) }
                return
            }
            if purchased {
                do {
                    try await Purchasely.syncPurchase(for: appleProductId)
                } catch {
                    SampleLogger.shared.addLog(message: "[StoreKit2][Observer Mode] syncPurchase failed: \(error)")
                }
            }
        }
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func purchaseWithStoreKit2(for appleProductId: String,
                               with promoOfferId: String?,
                               interceptorInfo: PLYInterceptorInfo?,
                               completion: @escaping (PLYInterceptResult) -> Void) async throws -> Bool {

        // Every path below calls `completion` exactly once, on the main queue. A path that throws
        // before any `completion` call leaves it to the caller's `catch`.
        func finish(_ result: PLYInterceptResult, after: (() -> Void)? = nil) {
            DispatchQueue.main.async {
                completion(result)
                after?()
            }
        }

        if let promoOfferId = promoOfferId {

            // Token-aware signing: the token returned here goes unchanged into `appAccountToken`.
            Purchasely.signPromotionalOffer(storeProductId: appleProductId,
                                            storeOfferId: promoOfferId,
                                            purchaseContextToken: nil) { signature, token in

                guard let decodedSignature = Data(base64Encoded: signature.signature) else {
                    finish(.failed)
                    return
                }

                Task {
                    do {
                        var options: Set<Product.PurchaseOption> = []
                        options.insert(.appAccountToken(token))
                        options.insert(.promotionalOffer(offerID: signature.identifier,
                                                         keyID: signature.keyIdentifier,
                                                         nonce: signature.nonce,
                                                         signature: decodedSignature,
                                                         timestamp: Int(signature.timestamp)))

                        guard let product = try await Product.products(for: [appleProductId]).first else {
                            finish(.failed)
                            return
                        }
                        switch try await product.purchase(options: options) {
                        case .userCancelled, .pending:
                            SampleLogger.shared.addLog(message: "Purchase with promo offer: userCancelled")
                            finish(.success)
                        case .success(.unverified(_, let error)):
                            SampleLogger.shared.addLog(message: "Purchase with promo offer: unverified \(error.localizedDescription)")
                            finish(.success)
                        case .success(.verified(let transaction)):
                            SampleLogger.shared.addLog(message: "Purchase with promo offer: verified")
                            await transaction.finish()
                            finish(.success) { interceptorInfo?.controller?.dismiss(animated: true) }
                        @unknown default:
                            finish(.failed)
                        }
                        await MainActor.run { self.viewState = .content }
                    } catch {
                        SampleLogger.shared.addLog(message: "Purchase with promo offer failed: \(error)")
                        finish(.failed)
                    }
                }
            } failure: { error in
                DispatchQueue.main.async { self.viewState = .failure(error.localizedDescription) }
                finish(.failed)
            }
            return false
        }

        guard let product = try await Product.products(for: [appleProductId]).first else {
            finish(.failed)
            return false
        }
        let purchased: Bool
        switch try await product.purchase() {
        case .userCancelled, .pending:
            SampleLogger.shared.addLog(message: "Purchase: userCancelled")
            finish(.success)
            purchased = false
        case .success(.unverified(_, let error)):
            SampleLogger.shared.addLog(message: "Purchase: unverified \(error.localizedDescription)")
            finish(.success)
            purchased = false
        case .success(.verified(let transaction)):
            SampleLogger.shared.addLog(message: "Purchase: verified")
            await transaction.finish()
            finish(.success)
            purchased = true
        @unknown default:
            finish(.failed)
            purchased = false
        }
        await MainActor.run { self.viewState = .content }
        return purchased
    }
    
    private func presentLogin(above controller: UIViewController, loggedIn: @escaping ((Bool) -> Void)) {
        //TODO: - Login View
    }
    
    func presentTermsAndConditions(above controller: UIViewController, answered: @escaping ((Bool) -> Void)) {
        //TODO: - Terms and conditions View
    }
}

@objc class PaymentTransactionObserver: NSObject, SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        let observerMode = EnvironmentRepository.shared.isObserverModeEnabled()
        guard observerMode else { return }
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                queue.finishTransaction(transaction)
            default:
                break
            }
        }
    }
}

class ProductRequestDelegate: NSObject, SKProductsRequestDelegate {
    
    var offerSignature: PLYOfferSignature?
    /// Token returned by the token-aware `signPromotionalOffer`. Apple compares the signature with
    /// `applicationUsername`, so it goes there unchanged (lowercased).
    var purchaseContextToken: UUID?
    var didFinish: () -> () = { }
    var didFinishWithError: () -> () = { }
    var completion: (PLYInterceptResult) -> Void = { _ in }

    func requestDidFinish(_ request: SKRequest) {
        didFinish()
        completion(.success)
    }
        
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard SKPaymentQueue.canMakePayments() else {
            didFinishWithError()
            completion(.failed)
            return
        }

        guard let product = response.products.first else {
            didFinishWithError()
            completion(.failed)
            return
        }
        
        let payment = SKMutablePayment(product: product)

        if let signature = offerSignature, let token = purchaseContextToken {
            payment.applicationUsername = token.uuidString.lowercased()
            payment.paymentDiscount = SKPaymentDiscount(identifier: signature.identifier,
                                                        keyIdentifier: signature.keyIdentifier,
                                                        nonce: signature.nonce,
                                                        signature: signature.signature,
                                                        timestamp: NSNumber(value: signature.timestamp))
        }
        
        SKPaymentQueue.default().add(payment)
    }
}
