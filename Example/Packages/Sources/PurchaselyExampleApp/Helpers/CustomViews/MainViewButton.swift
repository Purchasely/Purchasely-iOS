//
//  MainViewButton.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 13/12/2023.
//

import SwiftUI

struct MainViewButton: View {
    var text: String
    var defaultColor: Bool = true
    
    var body: some View {
        Text(text).frame(maxWidth: .infinity, minHeight: 50)
            .bold()
            .background(defaultColor ? .white : .main)
            .foregroundColor(defaultColor ? .black : .white)
            .cornerRadius(12)
    }
}

#Preview {
    MainViewButton(text: "Preview")
}
