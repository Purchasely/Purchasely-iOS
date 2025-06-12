//
//  ProductsView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 15/12/2023.
//

import SwiftUI
import Purchasely

class ProductTest {
    var identifier: String = "identifier"
    var vendorId: String = "vendorId"
    var internalId: String = "internalId"
}

struct ProductsView: View {

    @StateObject var viewModel = ProductsViewModel()
    
    var body: some View {
        
        VStack {
            
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Products and Plans", displayMode: .inline)
            
            VStack {
                ProductListView()
            }
            .padding(.top, 16)
            .background(Color.white)
            .searchable(text: $viewModel.searchQuery, prompt: "Products and Plans")
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }
}

extension ProductsView {

    func ProductListView() -> some View {
        List {
            ForEach(viewModel.searchResults, id: \.vendorId) { plyProduct in
                Section(content: {
                    PlansView(plyProduct)
                }, header: {
                    ProductTitleView(plyProduct)
                })
            }
        }
        .listRowSpacing(10)
        .scrollContentBackground(.hidden)
    }
    
    func PlansView(_ plyProduct: SampleProductObject) -> some View {
        ForEach(plyProduct.plans, content: PlanView.init(plan:))
    }
    
    func ProductTitleView(_ plyProduct: SampleProductObject) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(plyProduct.name)
                    .font(.title3)
                    .bold()
                
                Text(plyProduct.vendorId)
                    .font(.body)
            }
            Spacer()
            ZStack {
                Capsule()
                    .frame(width: 80, height: 30)
                    .foregroundColor(Color.main)
                Text("\(plyProduct.plans.count) plans")
                    .foregroundColor(.white)
                    .bold()
            }
        }
        .padding(.bottom, 26)
    }
}

struct PlanView: View {
    @State var isExpanded: Bool = false

    let plan: SamplePlanObject
    
    init(plan: SamplePlanObject) {
        self.plan = plan
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                Spacer()
                Button {
                    UIPasteboard.general.string = plan.vendorId
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.white)
                        .frame(width: 35, height: 35)
                }
                .buttonStyle(.plain)
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(plan.vendorId)
                    Text(plan.appleProductId)
                }
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    isExpanded.toggle()
                }, label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .frame(width: 35, height: 35)
                })
                .buttonStyle(.plain)
                .font(.body)
            }
            if isExpanded {
                Spacer()
                    .frame(height: 20)
                labelWithValue("localized price", with: plan.plyPlan.localizedPrice())
                labelWithValue("localized full price", with: plan.plyPlan.localizedFullPrice())
                labelWithValue("localized intro. price", with: plan.plyPlan.localizedIntroductoryPrice())
                labelWithValue("localized full intro. price", with: plan.plyPlan.localizedFullIntroductoryPrice())
                Divider()
                labelWithValue("intro. period", with: plan.plyPlan.introductoryPeriod())
                labelWithValue("localized period", with: plan.plyPlan.localizedPeriod())
                labelWithValue("localized intro. period", with: plan.plyPlan.localizedIntroductoryPeriod())
                Divider()
                labelWithValue("duration", with: plan.plyPlan.duration)
                labelWithValue("intro. duration", with: plan.plyPlan.introductoryDuration())
                labelWithValue("localized intro. duration", with: plan.plyPlan.localizedIntroductoryDuration())
                Divider()
                labelWithValue("amount", with: plan.plyPlan.amount)
                labelWithValue("currency code", with: plan.plyPlan.currencyCode)
                labelWithValue("currency symbol", with: plan.plyPlan.currencySymbol)
            }
        }
        .font(.subheadline)
        .listRowBackground(Color.mainLight)
    }
    
    func labelWithValue<T: CustomStringConvertible>(_ string: String, with value: T?) -> Text {
        Text("\(string): \(value?.description ?? "nil")")
    }
}

#Preview {
    ProductsView()
}
