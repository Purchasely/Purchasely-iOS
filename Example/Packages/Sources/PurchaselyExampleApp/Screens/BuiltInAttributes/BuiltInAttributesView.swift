//
//  BuiltInAttributesView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 31/05/2024.
//

import SwiftUI

struct BuiltInAttributesView: View {
    
    @StateObject private var viewModel = BuiltInAttributesViewModel()
    
    var body: some View {
        ContentView().onAppear() {
            viewModel.loadAttributes()
        }
    }
    
    @ViewBuilder
    func ContentView() -> some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Built-in attributes", displayMode: .inline)
            
            Button(action: viewModel.clearBuiltInAttributes, label: {
                Text("Clear")
                    .frame(maxWidth: .infinity)
                    .bold()
                    .foregroundColor(.main)
            }).tint(.white)
                .controlSize(.large) // .large, .medium or .small
                .buttonStyle(.borderedProminent)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
            
            ZStack(alignment: .top) {
                Color.backgroundGrey
                
                List {
                    ForEach(viewModel.attributes, id: \.identifier) { attribute in
                        VStack(alignment: .leading) {
                            Text("\(attribute.key)")
                                .fontWeight(.thin)
                                .multilineTextAlignment(.leading)
                            Text("\(attribute.value)")
                                .font(.title2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }.listRowSpacing(10)
                    .scrollContentBackground(.hidden)
                
            }.background(Color.backgroundGrey)
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }
}

#Preview {
    BuiltInAttributesView()
}
