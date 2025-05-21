//
//  DirectPurchaseViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 20/03/2024.
//

import Foundation
import Purchasely
import StoreKit

class DirectPurchaseViewModel: ObservableObject {
    
    enum PurchaseViewState {
        case loading
        case content
        case success
        case failure(String?)
    }
    
    @Published var toast: PLYToast? = nil
    @Published var viewState: PurchaseViewState = .content
    @Published var isObserverModeEnabled: Bool = false
    
    var productRequestDelegate: ProductRequestDelegate?
    
    func getRunningMode() {
        isObserverModeEnabled = EnvironmentRepository.shared.isObserverModeEnabled()
    }
    
    func purchase(planId: String, contentId: String, storeOfferId: String) {
        
        self.viewState = .loading
        
        let _planId = planId.isEmpty ? nil : planId
        let _contentId = contentId.isEmpty ? nil : contentId
        let _storeOfferId = storeOfferId.isEmpty ? nil : storeOfferId
        
        guard let planId = _planId else {
            self.toast = PLYToast(type: .error, title: "Error", message: "Plan id cannot be empty")
            self.viewState = .failure("")
            return
        }
        
        if isObserverModeEnabled {
            Task { [weak self] in
                await self?.observerModePurchase(planId: planId, _storeOfferId: _storeOfferId, _contentId: _contentId)
            }
        } else {
            self.fullModePurchase(planId: planId, _storeOfferId: _storeOfferId, _contentId: _contentId)
        }
    }
    
    func fullModePurchase(planId: String,
                          _storeOfferId: String?,
                          _contentId: String?) {
        
        Purchasely.plan(with: planId) { plan in
            if let storeOfferId = _storeOfferId {
                Purchasely.purchaseWithPromotionalOffer(plan: plan,
                                                        contentId: _contentId,
                                                        storeOfferId: storeOfferId) {
                    //TODO: Purchase SUCCESS
                    self.toast = PLYToast(type: .success, title: "Purchase Success", message: "Plan with id: \(plan.vendorId) successfully purchased with promotional offer \(storeOfferId)")
                    self.viewState = .success
                } failure: { error in
                    //TODO: Purchase FAILURE
                    self.toast = PLYToast(type: .error, title: "Purchase Failure", message: "Failed to purchase plan with id: \(plan.vendorId) and promotional offer (\(storeOfferId)), Error: \(error.localizedDescription)")
                    self.viewState = .failure(error.localizedDescription)
                }
                
            } else {
                
                Purchasely.purchase(plan: plan, contentId: _contentId) {
                    //TODO: Purchase SUCCESS
                    self.toast = PLYToast(type: .success, title: "Purchase Success", message: "Plan with id: \(plan.vendorId) successfully purchased")
                    self.viewState = .success
                } failure: { error in
                    //TODO: Purchase FAILURE
                    self.toast = PLYToast(type: .error, title: "Purchase Failure", message: "Failed to purchase plan with id: \(plan.vendorId), Error: \(error.localizedDescription)")
                    self.viewState = .failure(error.localizedDescription)
                }
            }
            
        } failure: { error in
            //TODO: Get Plan FAILURE
            self.toast = PLYToast(type: .error, title: "Failure", message: "Failed to get plan with id: \(planId). Error: \(error?.localizedDescription ?? "--error--")")
            self.viewState = .failure(error?.localizedDescription)
        }}
    
    func observerModePurchase(planId: String,
                              _storeOfferId: String?,
                              _contentId: String?) async {
        
        Purchasely.plan(with: planId, success: { plan in
            guard let appleProductId = plan.appleProductId else { return }
            
            if EnvironmentRepository.shared.isStorekit2Enabled() {
                Task { [weak self] in
                    guard let `self` = self else { return }
                    do {
                        let purchased = try await self.purchaseWithStoreKit2(for: appleProductId, with: _storeOfferId)
                        if purchased {
                            try await Purchasely.syncPurchase(for: appleProductId)
                        }
                    } catch {
                        self.toast = PLYToast(type: .error, title: "Failure", message: "Failed to purchase plan with id: \(planId). Error: \(error.localizedDescription)")
                        self.viewState = .failure(error.localizedDescription)
                    }
                }
                
            } else {
                self.storeKit1PurchaseProcess(appleProductId: appleProductId, storeOfferId: _storeOfferId)
            }
        }, failure: { error in
            self.toast = PLYToast(type: .error, title: "Failure", message: "Failed to get plan with id: \(planId). Error: \(error?.localizedDescription ?? "--error--")")
            self.viewState = .failure(error?.localizedDescription)
        })
    }
    
    func storeKit1PurchaseProcess(appleProductId: String, storeOfferId: String?) {
        if let storeOfferId = storeOfferId {
            Purchasely.signPromotionalOffer(storeProductId: appleProductId, storeOfferId: storeOfferId) { signature in
                let request = SKProductsRequest(productIdentifiers: Set<String>([appleProductId]))
                self.productRequestDelegate = ProductRequestDelegate()
                self.productRequestDelegate?.offerSignature = signature
                self.productRequestDelegate?.didFinish = { self.viewState = .success }
                self.productRequestDelegate?.didFinishWithError = {
                    self.toast = PLYToast(type: .error, title: "Failure", message: "Failed to purchase")
                    self.viewState = .failure(nil)
                }
                
                request.delegate = self.productRequestDelegate // Get Product in the `productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse)` method
                request.start()
            } failure: { error in
                self.toast = PLYToast(type: .error, title: "Failure", message: "Failed to get sign promotional offer with id: \(storeOfferId). Error: \(error.localizedDescription)")
                self.viewState = .failure(error.localizedDescription)
            }

        } else {
            let request = SKProductsRequest(productIdentifiers: Set<String>([appleProductId]))
            productRequestDelegate = ProductRequestDelegate()
            productRequestDelegate?.didFinish = { self.viewState = .success }
            productRequestDelegate?.didFinishWithError = {
                self.toast = PLYToast(type: .error, title: "Failure", message: "Failed to purchase")
                self.viewState = .failure(nil)
            }
            request.delegate = productRequestDelegate // Get Product in the `productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse)` method
            request.start()
        }
    }
    
    func purchaseWithStoreKit2(for appleProductId: String,
                               with promoOfferId: String?) async throws -> Bool {
        
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
                                self.toast = PLYToast(type: .error, title: "Cancelled", message: "Purchase with promo offer pending or cancelled")
                                self.viewState = .failure(nil)
                            case .success(let verificationResult):
                                switch verificationResult {
                                case .unverified(_, let error):
                                    self.toast = PLYToast(type: .error, title: "Failure", message: "Purchase plan with appleProductId: \(appleProductId) unverified. Error: \(error.localizedDescription)")
                                    self.viewState = .failure(error.localizedDescription)
                                case .verified(let transaction):
                                    await transaction.finish()
                                    self.viewState = .success
                                }
                            @unknown default:
                                break
                            }
                        }
                    }
                }
            } failure: { error in
                self.toast = PLYToast(type: .error, title: "Failure", message: "Purchase plan with appleProductId: \(appleProductId) unverified. Error: \(error.localizedDescription)")
                self.viewState = .failure(error.localizedDescription)
            }
        } else {
            
            if let product = try await Product.products(for: [appleProductId]).first {
                let purchaseResult = try await product.purchase()
                switch purchaseResult {
                case .userCancelled, .pending:
                    self.toast = PLYToast(type: .error, title: "Cancelled", message: "Purchase pending or cancelled")
                    self.viewState = .failure(nil)
                    return false
                case .success(let verificationResult):
                    switch verificationResult {
                    case .unverified(_, let error):
                        self.toast = PLYToast(type: .error, title: "Failure", message: "Purchase plan with appleProductId: \(appleProductId) unverified. Error: \(error.localizedDescription)")
                        self.viewState = .failure(error.localizedDescription)
                        return false
                    case .verified(let transaction):
                        await transaction.finish()
                        self.viewState = .success
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
}
