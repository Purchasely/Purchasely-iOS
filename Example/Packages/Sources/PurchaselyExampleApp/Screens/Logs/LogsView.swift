//
//  LogsView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 15/12/2023.
//

import SwiftUI
import Purchasely

struct LogsView: View {
    
    @StateObject private var logger = SampleLogger.shared
    @State private var filter = ""
        
    var body: some View {
        
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Logs", displayMode: .inline)
            
            VStack {
                
                HStack {
                    TextField("Filter", text: $filter, onEditingChanged: { _ in
                        if filter != "" {
                            logger.logs = logger.logs.filter { log in
                                return log.message.contains(filter)
                            }
                        } else {
                            logger.logs = logger.getLogs()
                        }
                    }).textFieldStyle(CustomTextFieldStyle())
                        .padding(.horizontal)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    Button("Clear") {
                        clearLogs()
                    }.tint(.main)
                        .controlSize(.large) // .large, .medium or .small
                        .buttonStyle(.borderedProminent)
                }.padding()
                
                HStack {
                    Text("Logs")
                        .bold()
                        .padding()
                }.frame(maxWidth: .infinity,
                        alignment: .leading)
                
                List(logger.logs.reversed()) { log in
                    VStack(alignment: .leading) {
                        switch log.logLevel {
                        case "Info":
                            Text("\(log.date.description)")
                                .bold()
                                .foregroundStyle(Color.black)
                            Text(log.message).foregroundStyle(Color.black)
                        case "Warn":
                            Text("\(log.date.description)")
                                .bold()
                                .foregroundStyle(Color.orange)
                            Text(log.message).foregroundStyle(Color.orange)
                        case "Error":
                            Text("\(log.date.description)")
                                .bold()
                                .foregroundStyle(Color.red)
                            Text(log.message).foregroundStyle(Color.red)
                        case "Sample":
                            Text("\(log.date.description)")
                                .bold()
                                .foregroundStyle(Color.blue)
                            Text(log.message).foregroundStyle(Color.blue)
                        default:
                            Text("\(log.date.description)")
                                .bold()
                                .foregroundStyle(Color.black)
                            Text(log.message).foregroundStyle(Color.black)
                        }
                        
                    }.listRowInsets(EdgeInsets())
                }.listRowSpacing(16)
                    .scrollContentBackground(.hidden)
                
            }.background(Color.white)
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
        .onAppear() {
            Purchasely.addLogger(logger)
        }
    }
}

extension LogsView {
    
    func clearLogs() {
        logger.clearLogs()
    }
}

#Preview {
    LogsView()
}
