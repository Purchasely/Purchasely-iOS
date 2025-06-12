//
//  ProductsViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 22/12/2023.
//

import Combine
import Foundation
import Purchasely

struct SamplePlanObject: Identifiable {
    
    var id = UUID()
    var name: String
    var vendorId: String
    var appleProductId: String
    var offers: [String]
    
    var plyPlan: PLYPlan
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
    
    @Published private var plyProducts: [SampleProductObject] = []
    @Published var plyPlansStringList: [String] = []
    @Published var offersForPlan: [String] = []
    @Published var searchQuery: String = ""

    @Published var searchResults: [SampleProductObject] = []

    init() {
        $plyProducts
            .combineLatest($searchQuery.map(\.localizedLowercase)) { (products: [SampleProductObject], query: String) -> [SampleProductObject] in
                if query.isEmpty {
                    return products
                }
                let lowercasedQuery = query.lowercased()

                return products.compactMap(match(query: lowercasedQuery))
            }
            .assign(to: &$searchResults)
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
                                 offers: $0.promoOffers.map { $0.vendorId },
                                 plyPlan: $0) }
                .sorted(by: { $0.name < $1.name }))
            }
            .sorted(by: { $0.name < $1.name })
            
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

fileprivate func match(query: String) -> (_ product: SampleProductObject) -> SampleProductObject? {
    return { product in
        if product.name.lowercased().contains(query) || product.vendorId.lowercased().contains(query) {
            return product
        }

        let filteredPlans = product.plans.filter(match(query: query))
        
        guard !filteredPlans.isEmpty else { return nil }

        return SampleProductObject(
            id: product.id,
            vendorId: product.vendorId,
            name: product.name,
            plans: filteredPlans
        )
    }
}

fileprivate func match(query: String) -> (_ plan: SamplePlanObject) -> Bool {
    return { plan in
        plan.name.contains(query) ||
        plan.vendorId.contains(query) ||
        plan.appleProductId.contains(query)
    }
}
