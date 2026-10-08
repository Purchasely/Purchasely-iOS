//
//  DeeplinksView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 29/04/2024.
//

import SwiftUI

struct DeeplinksView: View {
    @State private var url: String = ""
    @State private var redeemToken: String = ""
    @State private var redeemAuid: String = ""
    @StateObject private var viewModel: DeeplinksViewModel

    init(mainViewModel: MainViewModel) {
        self._viewModel = StateObject(wrappedValue: DeeplinksViewModel(mainViewModel: mainViewModel))
    }

    var body: some View {
        ContentView()
    }

    func ContentView() -> some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Deeplink", displayMode: .inline)
            
            ZStack(alignment: .top) {
                Color.backgroundGrey

                VStack(spacing: 0) {
                    VStack {
                        VStack(spacing: 16) {

                            TextField("URL", text: $url)
                                .textFieldStyle(CustomTextFieldStyle())
                                .padding(.horizontal)
                                .padding(.top, 20)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .onAppear {
                                    UITextField.appearance().clearButtonMode = .whileEditing
                                }

                            Button(action: openDeeplink, label: {
                                Text("Open")
                                    .frame(maxWidth: .infinity)
                                    .bold()
                            }).tint(.main)
                                .controlSize(.large) // .large, .medium or .small
                                .buttonStyle(.borderedProminent)
                                .padding(.vertical, 16)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                        }

                    }
                    .card()
                    .padding(.top, 15)

                    // Web redemption: builds purchasely://ply/redeem/{token}?auid={auid} from a
                    // redemption token you obtained from your Purchasely web checkout.
                    VStack {
                        VStack(spacing: 16) {
                            TextField("Redeem token", text: $redeemToken)
                                .textFieldStyle(CustomTextFieldStyle())
                                .padding(.horizontal)
                                .padding(.top, 20)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()

                            TextField("auid (optional)", text: $redeemAuid)
                                .textFieldStyle(CustomTextFieldStyle())
                                .padding(.horizontal)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()

                            Button(action: redeem, label: {
                                Text("Redeem")
                                    .frame(maxWidth: .infinity)
                                    .bold()
                            }).tint(.main)
                                .controlSize(.large)
                                .buttonStyle(.borderedProminent)
                                .padding(.vertical, 16)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                .disabled(redeemToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                    }
                    .card()
                    .padding(.top, 15)
                }

            }.background(Color.backgroundGrey)
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }
    
    private func openDeeplink() {
        viewModel.openDeeplink(with: url)
    }

    private func redeem() {
        viewModel.redeem(token: redeemToken, auid: redeemAuid)
    }
}

#Preview {
    DeeplinksView(mainViewModel: MockMainViewModel())
}
