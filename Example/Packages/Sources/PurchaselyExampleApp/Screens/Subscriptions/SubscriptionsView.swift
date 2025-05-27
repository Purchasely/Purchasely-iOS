//
//  SubscriptionsView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 03/01/2024.
//

import SwiftUI

struct SubscriptionsView: View {
    
    @StateObject var viewModel: SubscriptionsViewModel = SubscriptionsViewModel()
    
    var body: some View {

        Group {
            VStack {
                Rectangle()
                    .foregroundColor(.main)
                    .frame(maxHeight: 1)
                    .navigationBarTitle("Subscriptions", displayMode: .inline)
                switch self.viewModel.viewState {
                case .content:
                    self.viewModel.subscriptionsView
                case .failure(let error):
                    Text(error ?? "")
                case .loading:
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }
            }.frame(maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .top)
            .background(Color.main)
        }.onAppear() {
            viewModel.loadSubscriptionsView()
        }
    }
}

#Preview {
    SubscriptionsView()
}
