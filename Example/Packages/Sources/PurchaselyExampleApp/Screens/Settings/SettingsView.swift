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
                    ApiKeyField()
                    Pickers()
                    SampleAppDisplaySection()
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
                Text("OBSERVER MODE")
                    .frame(alignment: .leading)
                    .font(.footnote)
                    .bold()
                Toggle(isOn: $viewModel.observerMode) {

                }.toggleStyle(SwitchToggleStyle(tint: .main))
            }.padding(.horizontal)
                .padding(.top, 25)

            HStack {
                Text("STOREKIT 2")
                    .frame(alignment: .leading)
                    .font(.footnote)
                    .bold()
                Toggle(isOn: $viewModel.storeKit2) {

                }.toggleStyle(SwitchToggleStyle(tint: .main))
            }.padding(.horizontal)

            HStack {
                Text("ALLOW CAMPAIGNS")
                    .frame(alignment: .leading)
                    .font(.footnote)
                    .bold()
                Toggle(isOn: $viewModel.allowCampaigns) {

                }.toggleStyle(SwitchToggleStyle(tint: .main))
            }.padding(.horizontal)
                .padding(.bottom, 25)

        }
        .unpaddedCard()
    }

    func SampleAppDisplaySection() -> some View {
        VStack(spacing: 16) {
            Text("DEFAULT DISPLAY")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
                .bold()
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.top, 16)

            Text("Controls single-tap on \"View Presentation\"")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.horizontal)

            // Display Method
            HStack {
                Text("METHOD")
                    .font(.footnote)
                    .bold()
                Spacer()
                Picker("", selection: $viewModel.selectedDisplayMethod) {
                    ForEach(DisplayMethodCategory.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(.main)
            }.padding(.horizontal)

            // Source Preference
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SOURCE")
                        .font(.footnote)
                        .bold()
                    Text("Auto = Placement if set, else Presentation")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                Picker("", selection: $viewModel.selectedSourcePreference) {
                    ForEach(SourceType.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(.main)
            }.padding(.horizontal)

            // Display Mode (contextual based on method)
            HStack {
                Text("DISPLAY MODE")
                    .font(.footnote)
                    .bold()
                Spacer()
                if viewModel.showsDisplayModePicker {
                    Picker("", selection: $viewModel.selectedDisplayMode) {
                        ForEach(viewModel.availableDisplayModes, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(.main)
                } else {
                    Text("N/A")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }.padding(.horizontal)

            // Async Loading
            HStack {
                Text("ASYNC LOADING")
                    .frame(alignment: .leading)
                    .font(.footnote)
                    .bold()
                Toggle(isOn: $viewModel.asyncLoading) {
                }.toggleStyle(SwitchToggleStyle(tint: .main))
            }.padding(.horizontal)
                .padding(.bottom, 16)
        }
        .unpaddedCard()
        .onChange(of: viewModel.selectedDisplayMethod) { _ in
            if !viewModel.availableDisplayModes.contains(viewModel.selectedDisplayMode) {
                viewModel.selectedDisplayMode = .modal
            }
        }
    }

    func ApiKeyField() -> some View {
        VStack(spacing: 16) {
            TextField("Api Key", text: $viewModel.apiKey)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)
                .padding(.vertical, 16)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .unpaddedCard()
    }
    
    @ViewBuilder
    func Pickers() -> some View {
        List {
            Picker("Theme", selection: $viewModel.selectedThemeMode) {
                ForEach(ThemeMode.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }.pickerStyle(.menu)
                .accentColor(.main)
                .padding(.vertical)
        }
        .frame(minHeight: 85)
        .listRowSeparator(.hidden)
        .listStyle(.inset)
        .scrollDisabled(true)
        .unpaddedCard()

        LanguagePicker()
    }

    /// Demonstrates `Purchasely.setLanguage(from:)` — forces the language used for paywall content and
    /// SDK error messages, independently of the device language.
    func LanguagePicker() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Explicit label rather than `Picker("Language", …)`: a `.menu` picker only renders its
            // own label inside a List/Form, and this card is a plain VStack.
            HStack {
                Text("LANGUAGE")
                    .font(.footnote)
                    .bold()
                Spacer()
                Picker("", selection: $viewModel.selectedLanguage) {
                    ForEach(SampleLanguage.allCases) {
                        Text($0.displayName).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(.main)
            }
            .padding(.top, 16)

            Text("Purchasely.setLanguage(from:) — applies on Save, to the next paywall fetch. "
                 + "System restores the device language.")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.bottom, 16)
        }
        .padding(.horizontal)
        .unpaddedCard()
    }
}

#Preview {
    SettingsView()
}
