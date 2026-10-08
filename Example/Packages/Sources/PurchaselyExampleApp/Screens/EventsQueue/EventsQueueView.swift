//
//  EventsQueueView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 14/02/2024.
//

import SwiftUI

struct EventsQueueView: View {
    
    @ObservedObject private var log = SDKEventLog.shared
    
    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("SDK events", displayMode: .inline)
        
            ZStack(alignment: .top) {
                Color.backgroundGrey
                VStack {
                    Text("Events the SDK reports to the event delegate, newest first. Events you emit yourself are listed on the Custom Events screen.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Button {
                        log.clear()
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .foregroundColor(.red)
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }.padding(.vertical, 8)
                    
                    EventsListView()
                }.background(Color.backgroundGrey)
            }.background(Color.backgroundGrey)
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }

    func EventsListView() -> some View {
        List {
            ForEach(log.events) { attr in
                VStack(alignment: .leading) {
                    Text(attr.name)
                        .font(.title2)
                        .bold()
                    Text("\(attr.date.formatted(date: .omitted, time: .standard)) - properties: \(attr.properties.count)")
                        .font(.subheadline)
                }
            }
        }.listRowSpacing(10)
    }
}

#Preview {
    EventsQueueView()
}
