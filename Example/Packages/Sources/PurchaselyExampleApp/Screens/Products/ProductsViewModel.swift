//
//  ProductsViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 22/12/2023.
//

import Foundation
import Purchasely

struct SamplePlanObject: Identifiable {
    
    var id = UUID()
    var name: String
    var vendorId: String
    var appleProductId: String
    var offers: [String]
}

struct SampleProductObject: Identifiable, Hashable {
    static func == (lhs: SampleProductObject, rhs: SampleProductObject) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    var id = UUID()
    var vendorId: String
    var name: String
    var plans: [SamplePlanObject]
}

class ProductsViewModel: ObservableObject {
    
    @Published var plyProducts: [SampleProductObject] = []
    @Published var plyPlansStringList: [String] = []
    @Published var offersForPlan: [String] = []
    
    init() {
        loadProducts()
    }
    
    func loadProducts() {
        Purchasely.allProducts { products in
            self.plyProducts = products.map { SampleProductObject(vendorId: $0.vendorId,
                                                                  name: $0.name ?? "",
                                                                  plans: $0.plans.map {
                SamplePlanObject(name: $0.name ?? "",
                                 vendorId: $0.vendorId,
                                 appleProductId: $0.appleProductId ?? "",
                                 offers: $0.promoOffers.map { $0.vendorId }) })
            }
            
            for product in self.plyProducts {
                for plan in product.plans {
                    self.plyPlansStringList.append(plan.vendorId)
                }
            }
        } failure: { error in
            print(error.debugDescription)
        }
    }
    
    func getOffers(for planVendorId: String?) {
        guard let planVendorId = planVendorId else { return }
        for product in plyProducts {
            if let plan = product.plans.first(where: { $0.vendorId == planVendorId }) {
                DispatchQueue.main.async {
                    self.offersForPlan = plan.offers
                }
                return
            }
        }
        offersForPlan = []
    }
}
