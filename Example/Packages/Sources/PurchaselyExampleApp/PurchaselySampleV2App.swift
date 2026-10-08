//
//  PurchaselySampleV2App.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 13/12/2023.
//

import SwiftUI
import UIKit

@main
public struct PurchaselySampleV2App: App {

    public init() {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = .white
    }

    public var body: some Scene {
        WindowGroup {
            MainView()
                .onOpenURL { incomingURL in
                    print("App opened with URL: \(incomingURL)")
                }
                
        }
    }
}
