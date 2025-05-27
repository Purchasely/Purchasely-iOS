//
//  DeeplinksViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 29/04/2024.
//

import Foundation
import Purchasely

class DeeplinksViewModel: ObservableObject {
    
    func openDeeplink(with url: String) {
        guard let deeplinkURL = URL(string: url) else { return }
        Purchasely.isDeeplinkHandled(deeplink: deeplinkURL)
    }
}
