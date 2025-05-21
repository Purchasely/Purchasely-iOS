//
//  PaywallContainerView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 18/12/2023.
//

import SwiftUI
import Purchasely

struct PresentationContainerView: View {
        
    @StateObject var viewModel: PresentationContainerViewModel = PresentationContainerViewModel()
    
    var paywallIdentifier: String?
    
    init() { }
    
    init(paywallIdentifier: String?) {
        self.paywallIdentifier = paywallIdentifier
    }
    
    var body: some View {

        Group {
            switch self.viewModel.viewState {
            case .content:
                self.viewModel.paywallView
                
            case .failure(let error):
                Text(error.debugDescription)
                    .background(Color.red)
            case .loading:
                ProgressView().progressViewStyle(CircularProgressViewStyle())
            }
        }.onAppear() {
            if let paywallIdentifier = paywallIdentifier {
                viewModel.loadPresentation(paywallIdentifier: paywallIdentifier)
            } else {
                viewModel.loadCurrentPresentation()
            }
            
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    PresentationContainerView(paywallIdentifier: "")
}
