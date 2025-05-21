//
//  DirectPurchase.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 20/03/2024.
//

import SwiftUI

struct DirectPurchaseView: View {
    
    @State private var product: String = ""
    @State private var contentId: String = ""
    @State private var storeOfferId: String = ""
    
    @StateObject private var viewModel = DirectPurchaseViewModel()
    @StateObject var productsViewModel = ProductsViewModel()
    
    var body: some View {
        switch viewModel.viewState {
        case .loading:
            SpinnerView()
        case .failure( _):
            ContentView().toastView(toast: $viewModel.toast)
        case .success:
            ContentView().toastView(toast: $viewModel.toast)
        default:
            ContentView()
        }
    }
    
    @ViewBuilder
    func ContentView() -> some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Direct Purchase", displayMode: .inline)
            
            ZStack(alignment: .top) {
                Color.backgroundGrey
                
                VStack {
                    ParametersTextFields()
                }
                
            }.background(Color.backgroundGrey)
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
        .onAppear() {
            productsViewModel.loadProducts()
            viewModel.getRunningMode()
        }
    }
}

extension DirectPurchaseView {
    
    private func purchase() {
        viewModel.purchase(planId: product, contentId: contentId, storeOfferId: storeOfferId)
    }
    
    @ViewBuilder
    func ParametersTextFields() -> some View {
        Text("Running mode: \(viewModel.isObserverModeEnabled ? "Observer" : "Full")")
            .padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0))

        VStack {
            VStack(spacing: 16) {
                TextField("Plan", text: $product)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 25)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
                
                    Picker("Plans", selection: $product) {
                        ForEach(productsViewModel.plyPlansStringList, id: \.self) { product in
                            Text(product)
                        }
                    }.pickerStyle(.menu)
                    .accentColor(.main)
                        
                
                TextField("Content ID", text: $contentId)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
                
                TextField("Promo Offer", text: $storeOfferId)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
                
                Button(action: purchase, label: {
                    Text("Purchase")
                        .frame(maxWidth: .infinity)
                        .bold()
                }).tint(.main)
                    .controlSize(.large) // .large, .medium or .small
                    .buttonStyle(.borderedProminent)
                    .padding(.vertical, 16)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
            }
            
        }.background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.5), radius: 3, x: 1, y: 1)
            .padding(.horizontal, 15)
            .padding(.top, 15)
    }
}

#Preview {
    DirectPurchaseView()
}
