//
//  DeeplinksView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 29/04/2024.
//

import SwiftUI

struct DeeplinksView: View {
    @State private var url: String = ""
    @StateObject private var viewModel = DeeplinksViewModel()
    
    var body: some View {
        ContentView()
    }
    
    @ViewBuilder
    func ContentView() -> some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Deeplink", displayMode: .inline)
            
            ZStack(alignment: .top) {
                Color.backgroundGrey
                
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
                    
                }.background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.5), radius: 3, x: 1, y: 1)
                    .padding(.horizontal, 15)
                    .padding(.top, 15)
                
            }.background(Color.backgroundGrey)
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }
    
    private func openDeeplink() {
        viewModel.openDeeplink(with: url)
    }
}

#Preview {
    DeeplinksView()
}
