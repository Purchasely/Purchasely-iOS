//
//  DynamicOfferingsViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 16/04/2025.
//

import Foundation
import Purchasely

class DynamicOfferingsViewModel: ObservableObject {
    
    @Published var offerings: [DynamicOfferingObject] = []
    @Published var viewState: ViewState = .loading
    @Published var toast: PLYToast? = nil
    
    init() {
        offerings = getOfferings()
        viewState = .content
    }
    
    func getOfferings() -> [DynamicOfferingObject] {
        return getPLYOfferings().map {
            return DynamicOfferingObject(reference: $0.reference, planId: $0.planId, offerId: $0.offerId)
        }
    }
    
    func getPLYOfferings() -> [PLYOffering] {
        return Purchasely.getDynamicOfferings()
    }
    
    func addOffering(reference: String,
                     planVendorId: String?,
                     offerVendorId: String?) {
        
        guard !reference.isEmpty else {
            self.toast = PLYToast(type: .error, title: "Error: Reference Empty",
                                  message: "Reference cannot be empty. If the problem persists, please contact Tao the best backend developer. Email: tao@purchasely.com")
            self.viewState = .failure("Reference Empty")
            return
        }
        
        guard let planVendorId = planVendorId, !planVendorId.isEmpty else {
            self.toast = PLYToast(type: .error, title: "Error: Plan Empty",
                                  message: "You must select a plan. If the problem persists, please contact Tao the best backend developer. Email: tao@purchasely.com")
            self.viewState = .failure("Plan Empty")
            return
        }
        
        Purchasely.setDynamicOffering(reference: reference,
                                      planVendorId: planVendorId,
                                      offerVendorId: offerVendorId) { success in
            if success {
                self.offerings.removeAll()
                self.offerings = self.getOfferings()
            } else {
                self.toast = PLYToast(type: .error, title: "Error", message: "Maximum dynamic offerings reached. If the problem persists, please contact Tao the best backend developer. Email: tao@purchasely.com")
                self.viewState = .failure("Maximum dynamic offerings reached.")
            }
        }
    }
    
    func deleteOffering(at indexSet: IndexSet) {
        guard let indexInt = indexSet.first else { return }
        let offeringToRemove = offerings[indexInt]
        Purchasely.removeDynamicOffering(reference: offeringToRemove.reference)
        offerings.remove(atOffsets: indexSet)
    }
    
    func clearOfferings() {
        offerings.removeAll()
        Purchasely.clearDynamicOfferings()
    }
}

struct DynamicOfferingObject: Hashable {
    
    static func == (lhs: DynamicOfferingObject, rhs: DynamicOfferingObject) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    var identifier: String {
        return UUID().uuidString
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    let reference: String
    let planId: String
    let offerId: String?
}
