//
//  AttributesView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 15/12/2023.
//

import Purchasely
import SwiftUI

struct AttributesView: View {
    
    
    @State private var key: String = ""
    @State private var value: String = ""
    @State private var boolValue: Bool = false
    @State private var dateValue: Date = Date()
    
    @State private var selectedType: AttributesViewModel.Types = .Bool
    @State private var processingLegalBasis: PLYDataProcessingLegalBasis = .optional
    
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
            viewModel.addNewAttribute(key: self.key, value: self.value, processingLegalBasis: self.processingLegalBasis)
        case .Bool:
            viewModel.addNewAttribute(key: self.key, value: self.boolValue, processingLegalBasis: self.processingLegalBasis)
        case .Double:
            guard self.value != "",
                  let doubleValue = Double(value) else { return }
            viewModel.addNewAttribute(key: self.key, value: doubleValue, processingLegalBasis: self.processingLegalBasis)
        case .Int:
            guard self.value != "",
                  let intValue = Int(value) else { return }
            viewModel.addNewAttribute(key: self.key, value: intValue, processingLegalBasis: self.processingLegalBasis)
        case .Date:
            viewModel.addNewAttribute(key: self.key, value: self.dateValue, processingLegalBasis: self.processingLegalBasis)
        case .StringArray:
            let attributeArray: [String] = self.value.components(separatedBy: ";")
            viewModel.addNewAttribute(key: self.key, value: attributeArray, processingLegalBasis: self.processingLegalBasis)
        case .BoolArray:
            let attributeArray: [Bool] = self.value.components(separatedBy: ";")
                .compactMap { Bool($0) }
            viewModel.addNewAttribute(key: self.key, value: attributeArray, processingLegalBasis: self.processingLegalBasis)
        case .IntArray:
            let attributeArray: [Int] = self.value.components(separatedBy: ";")
                .compactMap { Int($0) }
            viewModel.addNewAttribute(key: self.key, value: attributeArray, processingLegalBasis: self.processingLegalBasis)
        case .DoubleArray:
            let attributeArray: [Double] = self.value.components(separatedBy: ";")
                .compactMap { Double($0) }
            viewModel.addNewAttribute(key: self.key, value: attributeArray, processingLegalBasis: self.processingLegalBasis)
        }
    }
    
    /// Increment / decrement work on the Int attribute named in "Key", by the Int in "Value" (1 if empty).
    private func step(_ change: (String, Int, PLYDataProcessingLegalBasis) -> Void) {
        guard key != "" else { return }
        change(key, Int(value) ?? 1, processingLegalBasis)
    }

    private func delete(indexSet: IndexSet?) {
        viewModel.removeAttribute(index: indexSet)
    }

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
                    Text(verbatim: "Processing Legal Basis: \(Self.name(for: attr.processingLegalBasis))")
                }
            }
            .onDelete(perform: delete)
            

        }.listRowSpacing(10)
    }

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
                
                List {
                    Picker("Processing Basis", selection: $processingLegalBasis) {
                        ForEach(PLYDataProcessingLegalBasis.allCases, id: \.self) {
                            Text(Self.name(for: $0))
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

                HStack {
                    Button("Increment") { step(viewModel.increment) }
                    Button("Decrement") { step(viewModel.decrement) }
                    Button("Clear all", role: .destructive) { viewModel.clearAll() }
                }
                .tint(.main)
                .buttonStyle(.bordered)
                .padding(.bottom, 16)
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
                
                Toggle(isOn: $boolValue) { }
                    .toggleStyle(SwitchToggleStyle(tint: .main))
                    .padding(24)
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
    
    static func name(for privacyFeaturesProcessingLegalBasis: PLYDataProcessingLegalBasis?) -> String {
        switch privacyFeaturesProcessingLegalBasis {
        case .optional:
            "consent"
        case .essential:
            "legitimate interest"
        case .none:
            "unknown"
        }
    }
}

#Preview {
    AttributesView()
}
