import SwiftUI

struct PrivacyView: View {
    @StateObject var viewModel = PrivacyViewModel()
    
    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Privacy", displayMode: .inline)
            List {
                ForEach(viewModel.privacyFeatures) { feature in
                    HStack {
                        Toggle(isOn: Binding<Bool>(
                            get: { feature.consentGranted },
                            set: { newValue in
                                if newValue { viewModel.grantConsentForFeature(feature.feature) }
                                else { viewModel.revokeConsentForFeature(feature.feature)}
                            })) {
                                Text(feature.feature.rawValue)
                        }
                    }
                }
            }
            .listRowSpacing(10)
            .scrollContentBackground(.hidden)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .top)
        .background(Color.main)
    }
}
