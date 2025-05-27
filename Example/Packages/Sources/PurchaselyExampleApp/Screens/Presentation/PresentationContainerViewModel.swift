//
//  PresentationViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 21/12/2023.
//

import Foundation
import SwiftUI
import Purchasely
import OHHTTPStubs
import StoreKit

class PresentationContainerViewModel: ObservableObject {
    
    @Published var viewState: ViewState = .loading
    @Published var paywallView: PLYPresentationView?
    @Published var isAsyncLoading: Bool = false
    
    var productRequestDelegate: ProductRequestDelegate?
    var controller: UIViewController?
    
    init() {
        isAsyncLoading = EnvironmentRepository.shared.isAsyncLoading()
    }
    
    private func injectPaywall(paywallTemplateFile: String) {
        HTTPStubs.stubRequests { request in
            return request.url?.absoluteString.contains("/presentations/Default") ?? false
        } withStubResponse: { _ in
            let stubPath = OHPathForFile("\(paywallTemplateFile.lowercased()).json", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type":"application/json"])
        }
    }
    
    func loadCurrentPresentation() {
        
        self.viewState = .loading
        let paywallIdentifier = EnvironmentRepository.shared.getPresentationId()
        let contentId = EnvironmentRepository.shared.getContentId()
        
        let completion: PLYProductViewControllerCompletionBlock = { (result, plan) in
            switch result {
            case .purchased:
                SampleLogger.shared.addLog(message: "[PLYProductViewControllerCompletionBlock] PURCHASED")
            case .restored:
                SampleLogger.shared.addLog(message: "[PLYProductViewControllerCompletionBlock] RESTORED")
            case .cancelled:
                SampleLogger.shared.addLog(message: "[PLYProductViewControllerCompletionBlock] CANCELLED")
            @unknown default:
                SampleLogger.shared.addLog(message: "[PLYProductViewControllerCompletionBlock] UNKNOWN")
            }
        }
        
        Purchasely.setPaywallActionsInterceptor { (action, parameters, presentationInfo, proceed) in
            self.paywallActionInterceptor(action: action,
                                          parameters: parameters,
                                          presentationInfo: presentationInfo,
                                          proceed: proceed)
        }
        
        
        if EnvironmentRepository.shared.isAsyncLoading() == true {
            //Async Loading
            if let placementId = EnvironmentRepository.shared.getPlacementId() {
                Purchasely.fetchPresentation(for: placementId,
                                             contentId: contentId,
                                             fetchCompletion: fetchCompletion(),
                                             completion: completion)
            } else {
                Purchasely.fetchPresentation(with: paywallIdentifier,
                                             contentId: contentId,
                                             fetchCompletion: fetchCompletion(),
                                             completion: completion,
                                             loadedCompletion: {
                    
                })
            }
        } else {
            
            //Sync Loading
            if let placementId = EnvironmentRepository.shared.getPlacementId() {
                self.controller = Purchasely.presentationController(for: placementId, contentId: contentId, loaded: { controller, _, _ in
                    self.paywallView = controller?.PresentationView
                    self.viewState = .content
                }, completion: completion)
            } else {
                self.controller = Purchasely.presentationController(with: paywallIdentifier, contentId: contentId, loaded: { controller,_,_ in
                    self.paywallView = controller?.PresentationView
                    self.viewState = .content
                }, completion: completion)
            }
        }
    }
    
    func loadPresentation(paywallIdentifier: String) {
        self.viewState = .loading
        if EnvironmentRepository.shared.isAsyncLoading() == true {
            Purchasely.fetchPresentation(with: paywallIdentifier,
                                         contentId: nil,
                                         fetchCompletion: fetchCompletion(),
                                         completion: nil,
                                         loadedCompletion: { 
                
            })
        } else {
            EnvironmentRepository.shared.setPresentationId(paywallIdentifier)
            
            self.controller = Purchasely.presentationController(with: paywallIdentifier, contentId: nil, loaded: { controller,_,_ in
                self.paywallView = controller?.PresentationView
                self.viewState = .content
            }, completion: nil)
        }
    }
    
    private func fetchCompletion() -> PLYPresentationFetchCompletionBlock {
        
        return { presentation, error in
            
            guard let paywallCtrl = presentation?.controller else {
                self.viewState = .failure("Error while prefetching presentation: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            self.paywallView = paywallCtrl.PresentationView
            self.viewState = .content
        }
    }
    
    private func paywallActionInterceptor(action: PLYPresentationAction,
                                  parameters: PLYPresentationActionParameters?,
                                  presentationInfo: PLYPresentationInfo?,
                                  proceed: @escaping (Bool) -> Void) -> Void {
        
        let observerMode = EnvironmentRepository.shared.isObserverModeEnabled()
        let storekit2Enabled = EnvironmentRepository.shared.isStorekit2Enabled()

        switch action {
            // Intercept the tap on login
        case .login:
            // When the user has completed the process
            // Pass true to reload the paywall or dismiss the paywall if the user already has an active subscription
            proceed(true)
        case .close:
            proceed(true)
        case .navigate:
            proceed(true)
        case .purchase:
            guard let plan = parameters?.plan,
                  let appleProductId = plan.appleProductId else {
                      proceed(false)
                      return
                  }
            
            if observerMode {
                if storekit2Enabled, #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    self.storeKit2PurchaseProcess(appleProductId: appleProductId,
                                                  promoOffer: parameters?.promoOffer,
                                                  presentationInfo: presentationInfo,
                                                  proceed: proceed)
                } else {
                    self.storeKit1PurchaseProcess(appleProductId: appleProductId, presentationInfo: presentationInfo, proceed: proceed)
                }
            } else {
                proceed(true)
            }
        default:
            proceed(true)
            break
        }
    }
    
    private func storeKit1PurchaseProcess(appleProductId: String, presentationInfo: PLYPresentationInfo?, proceed: @escaping (Bool) -> Void) {
        let request = SKProductsRequest(productIdentifiers: Set<String>([appleProductId]))
        productRequestDelegate = ProductRequestDelegate()
        productRequestDelegate?.proceed = proceed
        request.delegate = productRequestDelegate // Get Product in the `productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse)` method
        request.start()
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private func storeKit2PurchaseProcess(appleProductId: String,
                                          promoOffer: PLYPromoOffer?,
                                          presentationInfo: PLYPresentationInfo?,
                                          proceed: @escaping (Bool) -> Void) {
        Task { [weak self] in
            guard let `self` = self else { return }
            do {
                SampleLogger.shared.addLog(message: "[StoreKit2][Observer Mode] Purchasing \(appleProductId)")
                let purchased = try await self.purchaseWithStoreKit2(for:appleProductId,
                                                                     with: promoOffer?.storeOfferId,
                                                                     presentationInfo: presentationInfo,
                                                                     proceed: proceed)
                if purchased {
                    try await Purchasely.syncPurchase(for: appleProductId)
                }
            } catch {
                SampleLogger.shared.addLog(message: "[StoreKit2][Observer Mode] error with purchasing with StoreKit2: \(error)")
            }
        }
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func purchaseWithStoreKit2(for appleProductId: String,
                               with promoOfferId: String?,
                               presentationInfo: PLYPresentationInfo?,
                               proceed: @escaping (Bool) -> Void) async throws -> Bool {
        
        if let promoOfferId = promoOfferId {
            
            Purchasely.signPromotionalOffer(storeProductId: appleProductId,
                                            storeOfferId: promoOfferId) { signature in
                
                if let decodedSignature = Data(base64Encoded: signature.signature) {
                    
                    Task {
                        var options: Set<Product.PurchaseOption> = []
                        // ⚠️ MUST BE LOWERCASED ⚠️
                        
                        if let userId = EnvironmentRepository.shared.getUserId(),
                           let uuid = UUID(uuidString: userId.lowercased()) {
                            options.insert(.appAccountToken(uuid))
                        }
                        
                        let offerOption:Product.PurchaseOption = .promotionalOffer(offerID: signature.identifier,
                                                                                   keyID: signature.keyIdentifier,
                                                                                   nonce: signature.nonce,
                                                                                   signature: decodedSignature,
                                                                                   timestamp: Int(signature.timestamp))
                        options.insert(offerOption)
                        
                        if let product = try await Product.products(for: [appleProductId]).first {
                            let purchaseResult = try await product.purchase(options: options)
                            switch purchaseResult {
                            case .userCancelled, .pending:
                                SampleLogger.shared.addLog(message: "Purchase with promo offer: userCancelled")
                                DispatchQueue.main.async {
                                    proceed(false)
                                }
                            case .success(let verificationResult):
                                switch verificationResult {
                                case .unverified(_, let error):
                                    SampleLogger.shared.addLog(message: "Purchase with promo offer: unverified \(error.localizedDescription)")
                                    DispatchQueue.main.async {
                                        proceed(false)
                                    }
                                case .verified(let transaction):
                                    SampleLogger.shared.addLog(message: "Purchase with promo offer: verified")
                                    await transaction.finish()
                                    DispatchQueue.main.async {
                                        proceed(false)
                                        presentationInfo?.controller?.dismiss(animated: true)
                                    }
                                }
                            @unknown default:
                                break
                            }
                            self.viewState = .content
                        }
                    }
                }
            } failure: { error in
                self.viewState = .failure(error.localizedDescription)
            }
        } else {
            
            if let product = try await Product.products(for: [appleProductId]).first {
                let purchaseResult = try await product.purchase()
                switch purchaseResult {
                case .userCancelled, .pending:
                    SampleLogger.shared.addLog(message: "Purchase with promo offer: userCancelled")
                    self.viewState = .content
                    DispatchQueue.main.async {
                        proceed(false)
                    }
                    return false
                case .success(let verificationResult):
                    switch verificationResult {
                    case .unverified(_, let error):
                        SampleLogger.shared.addLog(message: "Purchase with promo offer: unverified \(error.localizedDescription)")
                        self.viewState = .content
                        DispatchQueue.main.async {
                            proceed(false)
                        }
                        return false
                    case .verified(let transaction):
                        SampleLogger.shared.addLog(message: "Purchase with promo offer: verified")
                        await transaction.finish()
                        self.viewState = .content
                        DispatchQueue.main.async {
                            proceed(false)
                        }
                        return true
                    }
                @unknown default:
                    return false
                }
            }
            return false
        }
        return false
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
    var didFinish: () -> () = { }
    var didFinishWithError: () -> () = { }
    var proceed: (Bool) -> Void = { _ in }
    
    func requestDidFinish(_ request: SKRequest) {
        didFinish()
        proceed(false)
    }
        
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Second Request payment
        guard SKPaymentQueue.canMakePayments() else {
            didFinishWithError()
            return
        }
        
        guard let product = response.products.first else {
            didFinishWithError()
            return
        }
        
        let payment = SKMutablePayment(product: product)
        
        payment.applicationUsername = Purchasely.anonymousUserId.lowercased() // lowercase anonymous user id is mandatory
        
        if let signature = offerSignature {
            let paymentDiscount = SKPaymentDiscount(identifier: signature.identifier,
                                                    keyIdentifier: signature.keyIdentifier,
                                                    nonce: signature.nonce,
                                                    signature: signature.signature,
                                                    timestamp: NSNumber(value: signature.timestamp))
            payment.paymentDiscount = paymentDiscount
        }
        
        SKPaymentQueue.default().add(payment)
    }
}
