//
//  MainView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 13/12/2023.
//

import SwiftUI
import Purchasely

@MainActor
struct MainView: View {
    @State private var showingSheet = false
    @State private var path = NavigationPath()
    
    @State private var showingQRCodeScannerSheet = false
    @State private var scannedCode: String? = nil
    
    @StateObject var viewModel: MainViewModel
    
    init(viewModel: MainViewModel = MainViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        
        //Use this if NavigationBarTitle is with Large Font
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        //Use this if NavigationBarTitle is with displayMode = .inline
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some View {
        
        Group {
            switch viewModel.viewState {
            case .loading:
                ZStack {
                    ContentView()
                    SpinnerView()
                }
            case .content:
                ContentView()
            case .failure( _):
                ContentView().toastView(toast: $viewModel.toast)
            }
        }.onAppear() {
            viewModel.InitPurchaselySDK()
            viewModel.loadConfiguration()
        }.onOpenURL { (url) in
            // Handle url here
            viewModel.handleDeeplink(url: url)
        }.preferredColorScheme(.light)
    }
    
    @ViewBuilder
    func ContentView() -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        QRCodeButton()
                        SettingsButton()
                    }
                    
                    Image.LogoSmall
                    Text("Purchasely Demo")
                        .foregroundColor(.white)
                        .font(.title)
                        .bold()
                    
                    Text(viewModel.sdkVersion)
                        .foregroundColor(.white)
                        .font(.title2)
                        .bold()
                
                    InfosView()
                    
                    ButtonsView()
                }
                .padding()
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .top)
                .navigationTitle("")
            }.background(Color.main)
            .alert(item: $viewModel.showAlert) { alert in
                    Alert(title: Text(alert.title), message: Text(alert.content ?? ""), dismissButton: .default(Text("Ok")))
                }
            .sheet(isPresented: $showingQRCodeScannerSheet) {
                // Present your QR code scanner view.
                // Assuming ContentView_QRCodeScanner is defined in your project
                // and accepts an onCodeScanned callback.
                QRCodeScannerView(scannedCode: $scannedCode)
                    .edgesIgnoringSafeArea(.all) // Allow camera to use full screen
                    .navigationBarTitleDisplayMode(.inline)
                    .onChange(of: scannedCode) { newValue in
                        if let code = newValue {
                            // Perform action
                            viewModel.handleScannedQRCode(code: code)
                            // Dismiss the sheet
                            showingQRCodeScannerSheet = false
                            scannedCode = nil
                        }
                    }
            }
        }
        .accentColor(.white)
    }
    
    @ViewBuilder
    func QRCodeButton() -> some View {

        Button(action: {
            self.showingQRCodeScannerSheet = true
        }) {
            Image(systemName: "qrcode")
                .foregroundColor(.white)
                .padding(.leading)
                .font(.title)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func SettingsButton() -> some View {
        NavigationLink {
            SettingsView()
        } label: {
            Image(systemName: "gearshape")
                .foregroundColor(.white)
                .padding(.trailing)
                .font(.title)
        }.frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    @ViewBuilder
    func InfosView() -> some View {
        if !viewModel.userId.isEmpty ||
            !viewModel.presentationId.isEmpty ||
            !viewModel.placementId.isEmpty ||
            !viewModel.contentId.isEmpty {
            Group {
                VStack(alignment: .leading, spacing: 8) {
                    
                    if !viewModel.userId.isEmpty {
                        InfoText(observedValue: viewModel.userId, title: "User ID")
                    }
                    if !viewModel.presentationId.isEmpty {
                        InfoText(observedValue: viewModel.presentationId, title: "Presentation ID")
                    }
                    if !viewModel.placementId.isEmpty {
                        InfoText(observedValue: viewModel.placementId, title: "Placement ID")
                    }
                    if !viewModel.contentId.isEmpty {
                        InfoText(observedValue: viewModel.contentId, title: "Content ID")
                    }
                }.padding()
            }.frame(maxWidth: .infinity,
                    maxHeight: .infinity)
            .background(Color(hex: "#FFFFFF", alpha: 0.3))
            .cornerRadius(24)
        }
    }
    
    @ViewBuilder
    func InfoText(observedValue: String, title: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(Color.white)
            HStack {
                Text(observedValue)
                    .foregroundStyle(Color.white)
                    .bold()
                Button {
                    UIPasteboard.general.string = observedValue
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.white)
                        .padding(.trailing)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func PresentationButton() -> some View {
        switch viewModel.displayMode {
        case .modal:
            Button(action: {
                showingSheet.toggle()
            }, label: {
                Text("View Presentation")
                    .frame(maxWidth: .infinity)
                    .bold()
                    .foregroundColor(.black)
            }).tint(.white)
                .controlSize(.large) // .large, .medium or .small
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            .sheet(isPresented: $showingSheet) {
                PresentationContainerView()
            }
        case .fullscreen:
            Button(action: {
                showingSheet.toggle()
            }, label: {
                Text("View Presentation")
                    .frame(maxWidth: .infinity)
                    .bold()
                    .foregroundColor(.black)
            }).tint(.white)
                .controlSize(.large) // .large, .medium or .small
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            .fullScreenCover(isPresented: $showingSheet) {
                PresentationContainerView()
            }
        case .push:
            NavigationLink(destination: PresentationContainerView()) {
                MainViewButton(text: "View Presentation")
            }
        }
    }
    
    @ViewBuilder
    func ButtonsView() -> some View {

        PresentationButton()
        
        NavigationLink(destination: DeeplinksView()) {
            MainViewButton(text: "Deeplinks")
        }
        
        NavigationLink(destination: ProductsView()) {
            MainViewButton(text: "Products and Plans")
        }
        
        NavigationLink(destination: DynamicOfferingsView()) {
            MainViewButton(text: "Dynamic Offerings")
        }

        ExpendableView(title: "Attributes") {
            NavigationLink(destination: AttributesView()) {
                MainViewButton(text: "User Attributes", defaultColor: false)
            }
            
            NavigationLink(destination: BuiltInAttributesView()) {
                MainViewButton(text: "Built-in Attributes", defaultColor: false)
            }
        }
        
        ExpendableView(title: "Subscriptions Methods") {
            NavigationLink(destination: DirectPurchaseView()) {
                MainViewButton(text: "Direct Purchase", defaultColor: false)
            }
            
            MainViewButton(text: "Synchronize/Restore", defaultColor: false)
                .onTapGesture {
                    self.viewModel.restore()
                }
            
            NavigationLink(destination: SubscriptionsView()) {
                MainViewButton(text: "Subscriptions", defaultColor: false)
            }
        }

        ExpendableView(title: "Events and Logs") {
            NavigationLink(destination: EventsQueueView()) {
                MainViewButton(text: "Events Queue", defaultColor: false)
            }
            
            NavigationLink(destination: LogsView()) {
                MainViewButton(text: "Logs", defaultColor: false)
            }
        }
    }
    
    struct ErrorView: View {
        
        @State private var error: String = "-"
        
        init(error: String?) {
            self.error = error ?? "Unknown Error"
        }
        
        var body: some View {
            Text("Error Initializing Purchasely SDK: \(self.error)")
        }
    }
}

#Preview {
    MainView()
}

struct ExpendableView<Content: View>: View {
    let title: String
    let secondaryColor: Bool
    let content: Content
    @State private var isExpanded = false

    init(title: String, secondaryColor: Bool? = false, @ViewBuilder content: @escaping () -> Content) {
        self.secondaryColor = secondaryColor ?? false
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(secondaryColor ? .white : .black)

            if isExpanded {
                content // Displays embedded views when expanded
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(secondaryColor ? Color.main.cornerRadius(10.0) : Color.white.cornerRadius(10.0))
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
}


// MARK: - PreviewProvider
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview 1: Content State
        MainView(viewModel: {
            let vm = MockMainViewModel()
            vm.viewState = .content
            vm.userId = "user_123_content"
            vm.presentationId = "pres_abc_content"
            vm.placementId = "" // Test empty state for some infos
            vm.contentId = "content_xyz_content"
            return vm
        }())
        .previewDisplayName("Content State")

        // Preview 2: Loading State
        MainView(viewModel: {
            let vm = MockMainViewModel()
            vm.viewState = .loading
            return vm
        }())
        .previewDisplayName("Loading State")

        // Preview 3: Failure State with Toast
        MainView(viewModel: {
            let vm = MockMainViewModel()
            
            // Toast will be shown by the .onAppear in MainView's failure case
            return vm
        }())
        .previewDisplayName("Failure State")

        // Preview 4: Content State with different display mode for PresentationButton
        MainView(viewModel: {
            let vm = MockMainViewModel()
            vm.viewState = .content
            vm.displayMode = .fullscreen // Test fullscreen presentation button
            vm.userId = "user_fullscreen"
            vm.presentationId = ""
            vm.placementId = ""
            vm.contentId = ""
            return vm
        }())
        .previewDisplayName("Content (Fullscreen Pres.)")

        // Preview 5: Content with many infos
        MainView(viewModel: {
            let vm = MockMainViewModel()
            vm.viewState = .content
            vm.userId = "very_long_user_id_string_for_testing_truncation_and_wrapping_behavior"
            vm.presentationId = "presentation_id_is_also_quite_long_indeed_yes"
            vm.placementId = "short_placement"
            vm.contentId = "content_id_with_some_more_details_to_see_how_it_looks"
            return vm
        }())
        .previewDisplayName("Content (Many Infos)")
    }
}

// Mock MainViewModel for controlling states in previews
@MainActor
class MockMainViewModel: MainViewModel {

    override func InitPurchaselySDK() {
        print("MockMainViewModel: InitPurchaselySDK called")
        viewState = .content
        toast = nil
        sdkVersion = "SDK vX.Y.Z (Preview)"
        userId = "preview_user_123"
        presentationId = "preview_presentation_abc"
        placementId = "preview_placement_xyz"
        contentId = "preview_content_123"
        showAlert = nil
        displayMode = .modal
    }

    override func loadConfiguration() {
        print("MockMainViewModel: loadConfiguration called")
        // Simulate configuration loading
    }

    override func handleDeeplink(url: URL) {
        print("MockMainViewModel: handleDeeplink called with \(url)")
//        self.toast = Toast(message: "Deeplink received (Preview): \(url.lastPathComponent)")
    }

    override func restore() {
        print("MockMainViewModel: restore called")
//        self.showAlert = AlertInfo(title: "Restore Triggered", content: "This is a preview of the restore action.")
    }
}
