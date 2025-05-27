//
//  EventsQueue.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 14/02/2024.
//

import SwiftUI

struct EventsQueueView: View {
    
    @StateObject private var viewModel = EventsQueueViewModel()
    
    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Queued Events", displayMode: .inline)
        
            ZStack(alignment: .top) {
                Color.backgroundGrey
                VStack {
                    Button {
                        viewModel.refreshEvents()
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .resizable()
                            .foregroundColor(.main)
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                    }.padding()
                    
                    EventsListView()
                }.background(Color.backgroundGrey)
            }.background(Color.backgroundGrey)
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }
    
    @ViewBuilder
    func EventsListView() -> some View {
        List {
            ForEach(viewModel.events, id: \.self) { attr in
                VStack(alignment: .leading) {
                    Text("\(attr.event)")
                        .font(.title2)
                        .bold()
                    Text("Properties count: \(attr.properties.count)")
                        .font(.title3)
                }
            }
        }.listRowSpacing(10)
    }
}

#Preview {
    EventsQueueView()
}
