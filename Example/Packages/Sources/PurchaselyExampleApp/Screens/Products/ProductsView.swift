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
    
    @State private var searchText = ""
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
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }
}

extension ProductsView {
    
    @ViewBuilder
    func ProductListView() -> some View {
        List {
            ForEach(viewModel.plyProducts, id: \.vendorId) { plyProduct in
                Section(content: {
                    PlansView(plyProduct)
                }, header: {
                    ProductTitleView(plyProduct)
                })
            }
        }.listRowSpacing(10)
            .scrollContentBackground(.hidden)
    }
    
    @ViewBuilder
    func PlansView(_ plyProduct: SampleProductObject) -> some View {
        ForEach(plyProduct.plans) { plan in
            VStack(alignment: .leading) {
                Text(plan.vendorId)
                    .bold()
                Text(plan.name)
                Text(plan.appleProductId)
                Button {
                    UIPasteboard.general.string = plan.vendorId
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.white)
                        .padding(.trailing)
                }
            }
            .listRowBackground(Color.mainLight)
        }
    }
    
    @ViewBuilder
    func ProductTitleView(_ plyProduct: SampleProductObject) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(plyProduct.name)
                    .font(.title3)
                    .bold()
                
                Text(plyProduct.vendorId)
                    .font(.body)
            }.padding(.trailing, 16)
            
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

#Preview {
    ProductsView()
}
