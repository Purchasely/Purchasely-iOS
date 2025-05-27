//
//  SubscriptionsViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 03/01/2024.
//

import Foundation
import SwiftUI
import Purchasely

class SubscriptionsViewModel: ObservableObject {
    
    @Published var viewState: ViewState = .loading
    @Published var subscriptionsView: SubscriptionsSwiftUIView?
    
    var controller: UIViewController?

    func loadSubscriptionsView() {
        self.viewState = .loading
        guard let controller = Purchasely.subscriptionsController() else {
            self.viewState = .failure("Error occured. Subscription screen cannot be displayd in Observer mode.")
            return
        }
        self.controller = controller
        self.subscriptionsView = SubscriptionsSwiftUIView(presentation: controller)
        self.viewState = .content
    }
}

public struct SubscriptionsSwiftUIView: UIViewControllerRepresentable {
    
    public typealias UIViewControllerType = UIViewController

    private let presentationViewController: UIViewControllerType!
    
    init(presentation: UIViewControllerType) {
        self.presentationViewController = presentation
    }

    public func makeUIViewController(context: Context) -> UIViewControllerType {
        presentationViewController
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
