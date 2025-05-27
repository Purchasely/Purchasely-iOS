//
//  SettingsView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 13/12/2023.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        
        Group {
            switch viewModel.viewState {
            case .loading:
                SpinnerView()
            case .content:
                SettingsViewBuilder()
            case .failure(let error):
                ErrorView(error: error)
            }
        }
    }
        
    struct ErrorView: View {
        
        @State private var error: String = "-"
        
        init(error: String?) {
            self.error = error ?? "Unknown Error"
        }
        
        var body: some View {
            Text("Error setting up Purchasely SDK: \(self.error)")
        }
    }
}

fileprivate extension SettingsView {
    
    func save() {
        viewModel.saveConfiguration() {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    @ViewBuilder
    func SettingsViewBuilder() -> some View {
        ZStack(alignment: .top) {
            Color.white
            
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 250)
                .ignoresSafeArea()
                .navigationBarTitle("Settings", displayMode: .inline)
            
            ScrollView {
                VStack(spacing: 24) {
                    Image.LogoLarge.padding(.vertical, 20)
                    IdsTextFields()
                    Toggles()
                    UrlTextFields()
                    Pickers()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
        }
        
        Button(action: save, label: {
            Text("Save").frame(maxWidth: .infinity)
        })
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .bold()
        .tint(.main)
        .foregroundColor(.white)
        .padding()
        .frame(alignment: .bottom)
        .onDisappear(perform: {
            viewModel.clear()
        })
    }

    func IdsTextFields() -> some View {
        VStack(spacing: 16) {
            TextField("User ID", text: $viewModel.userId)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .padding(.top, 25)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
            TextField("Presentation ID", text: $viewModel.presentationId)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
            TextField("Placement ID", text: $viewModel.placementId)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
            TextField("Content ID", text: $viewModel.contentId)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .padding(.bottom, 25)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
            
            
        }
        .unpaddedCard()
    }

    func Toggles() -> some View {
        VStack(spacing: 24) {
            HStack {
                Text("PRODUCTION")
                    .frame(alignment: .leading)
                    .font(.footnote)
                    .bold()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
            }.padding(.horizontal)
                .padding(.top, 25)
            
            HStack {
                Text("OBSERVER MODE")
                    .frame(alignment: .leading)
                    .font(.footnote)
                    .bold()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
                Toggle(isOn: $viewModel.observerMode) {
                    
                }.toggleStyle(SwitchToggleStyle(tint: .main))
            }.padding(.horizontal)
            
            HStack {
                Text("ASYNC LOADING")
                    .frame(alignment: .leading)
                    .font(.footnote)
                    .bold()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
                Toggle(isOn: $viewModel.asyncLoading) {
                    
                }.toggleStyle(SwitchToggleStyle(tint: .main))
            }.padding(.horizontal)
            
            HStack {
                Text("STOREKIT 2")
                    .frame(alignment: .leading)
                    .font(.footnote)
                    .bold()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
                Toggle(isOn: $viewModel.storeKit2) {
                    
                }.toggleStyle(SwitchToggleStyle(tint: .main))
            }.padding(.horizontal)
                .padding(.bottom, 25)
            
        }
        .unpaddedCard()
    }
    
    func UrlTextFields() -> some View {
        VStack(spacing: 16) {
            TextField("Api Key", text: $viewModel.apiKey)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .padding(.vertical, 16)
        }
        .unpaddedCard()
    }
    
    @ViewBuilder
    func Pickers() -> some View {
        List {
            Picker("Theme", selection: $viewModel.selectedThemeMode) {
                ForEach(SettingsViewModel.ThemeMode.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }.pickerStyle(.menu)
                .accentColor(.main)
                .padding(.vertical)
        }.frame(minHeight: 85)
            .listRowSeparator(.hidden)
            .listStyle(.inset)
            .scrollDisabled(true)
            .unpaddedCard()
        
        List {
            Picker("Display mode", selection: $viewModel.selectedDisplayMode) {
                ForEach(SettingsViewModel.DisplayMode.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }.pickerStyle(.menu)
                .accentColor(.main)
                .padding(.vertical)
        }.frame(minHeight: 85)
            .listRowSeparator(.hidden)
            .listStyle(.inset)
            .scrollDisabled(true)
            .unpaddedCard()
            .padding(.bottom, 18)
    }
}

#Preview {
    SettingsView()
}
