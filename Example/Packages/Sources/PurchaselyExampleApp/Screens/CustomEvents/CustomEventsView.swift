//
//  CustomEventsView.swift
//  PurchaselySampleV2
//
//  Three blocks: the campaigns switch, the emit form, the history of emitted events.
//

import Purchasely
import SwiftUI

struct CustomEventsView: View {

    @StateObject private var viewModel = CustomEventsViewModel()

    @State private var eventName: String = ""
    @State private var propertyKey: String = ""
    @State private var propertyValue: String = ""
    @State private var propertyBool: Bool = false
    @State private var propertyDate: Date = Date()
    @State private var propertyKind: CustomEventProperty.Kind = .string

    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Custom Events", displayMode: .inline)

            ZStack(alignment: .top) {
                Color.backgroundGrey
                ScrollView {
                    VStack(spacing: 15) {
                        CampaignsCard()
                        EmitCard()
                        HistoryCard()
                    }.padding(.bottom, 30)
                }
            }.background(Color.backgroundGrey)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.main)
    }

    // MARK: - 1. campaigns

    func CampaignsCard() -> some View {
        Card(title: "Campaigns") {
            Toggle("Purchasely.allowCampaigns", isOn: Binding(
                get: { viewModel.allowCampaigns },
                set: { viewModel.setAllowCampaigns($0) }
            )).toggleStyle(SwitchToggleStyle(tint: .main))
            Text("When on, emitting an event that a Console campaign listens to can open that campaign's screen.")
                .font(.footnote).foregroundColor(.gray)
        }
    }

    // MARK: - 2. emit

    func EmitCard() -> some View {
        Card(title: "Emit") {
            TextField("Event name (as declared in the Console)", text: $eventName)
                .textFieldStyle(CustomTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()

            Text("Properties").font(.headline).padding(.top, 8)
            TextField("Property key", text: $propertyKey)
                .textFieldStyle(CustomTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()
            Picker("Type", selection: $propertyKind) {
                ForEach(CustomEventProperty.Kind.allCases) { Text($0.rawValue) }
            }.pickerStyle(.segmented)
            PropertyValueField()
            Button(action: addProperty) {
                Text("Add property").frame(maxWidth: .infinity).bold()
            }.tint(.main).buttonStyle(.bordered).controlSize(.regular)

            if !viewModel.properties.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.properties) { property in
                        HStack {
                            Text(property.display).font(.footnote)
                            Spacer()
                            Button {
                                if let index = viewModel.properties.firstIndex(of: property) {
                                    viewModel.removeProperties(at: IndexSet(integer: index))
                                }
                            } label: { Image(systemName: "minus.circle").foregroundColor(.red) }
                        }
                    }
                }.padding(.top, 4)
            }

            Button {
                viewModel.emit(name: eventName)
            } label: {
                Text("Purchasely.emit").frame(maxWidth: .infinity).bold()
            }.tint(.main).buttonStyle(.borderedProminent).controlSize(.large).padding(.top, 8)

            if !viewModel.lastMessage.isEmpty {
                Text(viewModel.lastMessage).font(.footnote).foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    func PropertyValueField() -> some View {
        switch propertyKind {
        case .string:
            TextField("Value", text: $propertyValue)
                .textFieldStyle(CustomTextFieldStyle()).autocapitalization(.none).autocorrectionDisabled()
        case .int, .double:
            // Not `.decimalPad`: it shows the locale's separator only (a comma in French, no point) and has no
            // minus sign. This keyboard has both, and the view model accepts either separator for a Double.
            TextField("Value", text: $propertyValue)
                .textFieldStyle(CustomTextFieldStyle()).keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
        case .bool:
            Toggle("Value", isOn: $propertyBool).toggleStyle(SwitchToggleStyle(tint: .main))
        case .date:
            DatePicker("Value", selection: $propertyDate)
        }
    }

    private func addProperty() {
        let raw: String
        switch propertyKind {
        case .string, .int, .double: raw = propertyValue
        case .bool: raw = propertyBool ? "true" : "false"
        case .date: raw = ISO8601DateFormatter().string(from: propertyDate)
        }
        guard viewModel.addProperty(key: propertyKey, kind: propertyKind, rawValue: raw) else { return }
        propertyKey = ""
        propertyValue = ""
    }

    // MARK: - 3. history (in memory)

    func HistoryCard() -> some View {
        Card(title: "Emitted by this app", trailing: {
            Button { viewModel.clearHistory() } label: { Image(systemName: "trash.circle.fill").foregroundColor(.red) }
        }) {
            if viewModel.history.isEmpty {
                Text("Nothing emitted yet.").font(.footnote).foregroundColor(.gray)
            } else {
                ForEach(viewModel.history) { line in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(line.name).font(.body).bold()
                            Spacer()
                            Text(line.emittedAt, style: .time).font(.footnote).foregroundColor(.gray)
                            if line.typedProperties != nil {
                                Button { viewModel.retry(line) } label: {
                                    Image(systemName: "arrow.counterclockwise.circle.fill").foregroundColor(.main)
                                }.buttonStyle(.plain)
                            }
                        }
                        if line.properties.isEmpty {
                            Text("no property").font(.footnote).foregroundColor(.gray)
                        } else {
                            ForEach(line.properties, id: \.self) { Text($0).font(.footnote).foregroundColor(.gray) }
                        }
                    }
                    Divider()
                }
            }
        }
    }

    // MARK: - Card

    func Card<Content: View, Trailing: View>(title: String,
                                             @ViewBuilder trailing: () -> Trailing,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.title3).bold()
                Spacer()
                trailing()
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.5), radius: 3, x: 1, y: 1)
        .padding(.horizontal, 15)
        .padding(.top, 15)
    }

    func Card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        Card(title: title, trailing: { EmptyView() }, content: content)
    }
}

#Preview {
    CustomEventsView()
}
