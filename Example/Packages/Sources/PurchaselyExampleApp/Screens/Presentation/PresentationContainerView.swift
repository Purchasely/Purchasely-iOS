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
                    .overlay(alignment: .bottom) { InfoCard() }
                
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

extension PresentationContainerView {
    @ViewBuilder
    func InfoCard() -> some View {
        if let info = viewModel.info {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(info.rows, id: \.0) { row in
                    Text("\(row.0): \(row.1)")
                        .font(.caption2.monospaced())
                }
            }
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 24)
            .allowsHitTesting(false)
        }
    }
}

#Preview {
    PresentationContainerView(paywallIdentifier: "")
}
