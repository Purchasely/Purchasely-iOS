//
//  DynamicOfferingsView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 16/04/2025.
//

import SwiftUI

struct DynamicOfferingsView: View {
    
    @StateObject private var viewModel = DynamicOfferingsViewModel()
    @StateObject private var productsViewModel = ProductsViewModel()
    
    @State private var reference: String = ""
    @State private var plan: String?
    @State private var offer: String?
    
    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Dynamic Offerings", displayMode: .inline)
            
            ZStack(alignment: .top) {
                Color.backgroundGrey
                
                switch viewModel.viewState {
                case .content, .loading:
                    VStack {
                        DynamicOfferingsEditionView()
                        DynamicOfferingsListView()
                    }
                case .failure( _):
                    VStack {
                        DynamicOfferingsEditionView()
                        DynamicOfferingsListView()
                    }.toastView(toast: $viewModel.toast)
                }
            }.background(Color.backgroundGrey)
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }
    
    @ViewBuilder
    func DynamicOfferingsEditionView() -> some View {
        VStack {
            VStack(spacing: 16) {
                TextField("Reference", text: $reference)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 25)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
                
                HStack(spacing: 16) {
                    // PLAN PICKER
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.5), radius: 3, x: 1, y: 1)
                        
                        Picker("Plan", selection: $plan) {
                            if productsViewModel.plyPlansStringList.isEmpty {
                                Text("Select plan").tag(nil as String?)
                            } else {
                                ForEach(productsViewModel.plyPlansStringList, id: \.self) { product in
                                    Text(product).tag(Optional(product)) // tag with Optional
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(.main)
                        .padding(.horizontal)
                        .onChange(of: plan) { newValue in
                            offer = nil // reset offer when plan changes
                            productsViewModel.getOffers(for: newValue)
                        }
                    }
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    
                    // OFFER PICKER
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.5), radius: 3, x: 1, y: 1)
                        
                        Picker("Offer", selection: $offer) {
                            if productsViewModel.offersForPlan.isEmpty {
                                Text("No offers").tag(nil as String?)
                            } else {
                                ForEach(productsViewModel.offersForPlan, id: \.self) { offer in
                                    Text(offer).tag(Optional(offer))
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(.main)
                        .padding(.horizontal)
                    }
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                }
                .padding(12)
                
                Button(action: add, label: {
                    Text("Add")
                        .frame(maxWidth: .infinity)
                        .bold()
                }).tint(.main)
                    .controlSize(.large) // .large, .medium or .small
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 16)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
            }
            
        }.background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.5), radius: 3, x: 1, y: 1)
            .padding(.horizontal, 15)
            .padding(.top, 15)
    }
    
    @ViewBuilder
    func DynamicOfferingsListView() -> some View {
        List {
            ForEach(viewModel.offerings, id: \.self) { offering in
                VStack(alignment: .leading, spacing: 4) {
                    Text(offering.reference)
                        .font(.title2)
                        .bold()
                    Text("Plan ID: \(offering.planId)")
                        .font(.title3)
                    if let offerId = offering.offerId {
                        Text("Offer ID: \(offerId)")
                            .font(.body)
                    } else {
                        Text("Offer ID: nil")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: delete)
        }
        .listRowSpacing(10)
    }
    
    private func add() {
        viewModel.addOffering(reference: reference, planVendorId: plan, offerVendorId: offer)
    }
    
    // Dummy delete function — implement as needed
    func delete(at offsets: IndexSet) {
        viewModel.deleteOffering(at: offsets)
    }
    
}
