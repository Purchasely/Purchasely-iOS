//
//  AttributesView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 15/12/2023.
//

import SwiftUI

struct AttributesView: View {
    
    
    @State private var key: String = ""
    @State private var value: String = ""
    @State private var boolValue: Bool = false
    @State private var dateValue: Date = Date()
    
    @State private var selectedType: AttributesViewModel.Types = .Bool
    
    @StateObject private var viewModel = AttributesViewModel()
    
    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("User Attributes", displayMode: .inline)
            
            ZStack(alignment: .top) {
                Color.backgroundGrey
                
                VStack {
                    AttributeGroupView()
                    AttributesListView()
                }
                
            }.background(Color.backgroundGrey)
            
        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }
}

extension AttributesView {
    
    private func add() {
        
        guard self.key != "" else { return }
        
        switch selectedType {
        case .String:
            guard self.value != "" else { return }
            viewModel.addNewAttribute(key: self.key, value: self.value)
        case .Bool:
            viewModel.addNewAttribute(key: self.key, value: self.boolValue)
        case .Double:
            guard self.value != "",
                  let doubleValue = Double(value) else { return }
            viewModel.addNewAttribute(key: self.key, value: doubleValue)
        case .Int:
            guard self.value != "",
                  let intValue = Int(value) else { return }
            viewModel.addNewAttribute(key: self.key, value: intValue)
        case .Date:
            viewModel.addNewAttribute(key: self.key, value: self.dateValue)
        case .StringArray:
            let attributeArray: [String] = self.value.components(separatedBy: ";")
            viewModel.addNewAttribute(key: self.key, value: attributeArray)
        case .BoolArray:
            let attributeArray: [Bool] = self.value.components(separatedBy: ";")
                .compactMap { Bool($0) }
            viewModel.addNewAttribute(key: self.key, value: attributeArray)
        case .IntArray:
            let attributeArray: [Int] = self.value.components(separatedBy: ";")
                .compactMap { Int($0) }
            viewModel.addNewAttribute(key: self.key, value: attributeArray)
        case .DoubleArray:
            let attributeArray: [Double] = self.value.components(separatedBy: ";")
                .compactMap { Double($0) }
            viewModel.addNewAttribute(key: self.key, value: attributeArray)
        }
    }
    
    private func delete(indexSet: IndexSet?) {
        viewModel.removeAttribute(index: indexSet)
    }
    
    @ViewBuilder
    func AttributesListView() -> some View {
        List {
            ForEach(viewModel.attributes, id: \.self) { attr in
                VStack(alignment: .leading) {
                    Text("\(attr.key)")
                        .font(.title2)
                        .bold()
                    Text("Type: \(attr.type)")
                        .font(.title3)
                    Text(verbatim: "Value: \(attr.value)")
                }
            }
            .onDelete(perform: delete)
            

        }.listRowSpacing(10)
    }
    
    @ViewBuilder
    func AttributeGroupView() -> some View {
        VStack {
            VStack(spacing: 16) {
                TextField("Key", text: $key)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 25)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
                
                List {
                    Picker("Type", selection: $selectedType) {
                        ForEach(AttributesViewModel.Types.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }.pickerStyle(.menu)
                        .accentColor(.main)
                        .padding(.vertical)
                }.frame(height: 80)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .listRowSeparator(.hidden)
                    .listStyle(.inset)
                    .shadow(color: .gray.opacity(0.5), radius: 3, x: 1, y: 1)
                
                ValueTextFieldView()
                
                Button(action: add, label: {
                    Text("Add")
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
    }
    
    @ViewBuilder
    func ValueTextFieldView() -> some View {
        switch selectedType {
        case .String:
            TextField("Value", text: $value)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
        case .Bool:
            HStack {
                Text("Value").padding(.horizontal)
                    .padding(.leading)
                
                if #available(iOS 17.0, *) {
                    Toggle(isOn: $boolValue) { }
                        .toggleStyle(SwitchToggleStyle(tint: .main))
                        .padding(24)
                        .onChange(of: boolValue) {
                            
                        }
                } else {
                    Toggle(isOn: $boolValue) { }
                        .toggleStyle(SwitchToggleStyle(tint: .main))
                        .padding(24)
                        .onChange(of: boolValue, perform: { value in
                            
                        })
                }
            }
        case .Double, .Int:
            TextField("Value", text: $value)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }.keyboardType(.decimalPad)
        case .Date:
            DatePicker("Date", selection: $dateValue)
                .padding(24)
        case .StringArray, .BoolArray, .IntArray, .DoubleArray:
            TextField("Array (; separated values)", text: $value)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
        }
    }
}

#Preview {
    AttributesView()
}
