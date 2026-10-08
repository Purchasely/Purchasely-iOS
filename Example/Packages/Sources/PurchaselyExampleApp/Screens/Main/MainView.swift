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
    // Screen navigation is router-driven; paywall presentation stays local @State below.
    @StateObject private var router = AppRouter()
    @State private var selectedSampleDisplayMode: DisplayMode = .modal

    @State private var showingQRCodeScannerSheet = false
    @State private var scannedCode: String? = nil
    @State private var showPushPresentation = false
    @State private var pushPaywallIdentifier: String? = nil

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
                ContentView()
            }
        }
        // Attached to the Group, not to one branch. It used to hang off `.failure` alone, which was
        // enough for the only toast that existed then (SDK init failed → the view is in `.failure`
        // by definition). The web-redemption delegate toast fires while the app sits in `.content`,
        // so a per-branch modifier would have silently dropped it.
        .toastView(toast: $viewModel.toast)
        .onAppear() {
            viewModel.InitPurchaselySDK()
            viewModel.loadConfiguration()
        }.onOpenURL { (url) in
            // Handle url here
            viewModel.openDeeplink(url: url.absoluteString)
        }.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = (activity.webpageURL ?? activity.userInfo?["url"] as? URL) else { return }
            viewModel.openDeeplink(url: url.absoluteString)
          }
        .preferredColorScheme(.light)
    }

    func ContentView() -> some View {
        NavigationStack(path: $router.path) {
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
            // The SDK keeps one interceptor per action, and the Presentation screen replaces them.
            // Registering again when this screen is back keeps the Observer purchase working.
            .onAppear { if viewModel.didStart { viewModel.setupPaywallInterceptor() } }
            .alert(item: $viewModel.showAlert) { alert in
                    // Fall back to the error message (mirrors the SDK's controller(for:error:)):
                    // the redemption "expired" alert has content == nil and carries its
                    // (email_hint-templated) body via the error.
                    Alert(title: Text(alert.title), message: Text(alert.content ?? viewModel.alertErrorMessage ?? ""), dismissButton: .default(Text("Ok")))
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
                            viewModel.openDeeplink(url: code)
                            // Dismiss the sheet
                            showingQRCodeScannerSheet = false
                            scannedCode = nil
                        }
                    }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
        }
        .accentColor(.white)
    }

    // Maps a shared AppRoute to its iOS screen. Route decisions live in AppRouter.
    @ViewBuilder
    func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .settings:          SettingsView()
        case .deeplinks:         DeeplinksView(mainViewModel: viewModel)
        case .products:          ProductsView()
        case .subscriptions:     SubscriptionsView()
        case .dynamicOfferings:  DynamicOfferingsView()
        case .attributes:        AttributesView()
        case .builtInAttributes: BuiltInAttributesView()
        case .directPurchase:    DirectPurchaseView()
        case .eventsQueue:       EventsQueueView()
        case .customEvents:      CustomEventsView()
        case .logs:              LogsView()
        case .privacy:           PrivacyView()
        }
    }

    /// Presentation replaces the SDK's per-action interceptors; put Main's back when it closes.
    private func restoreInterceptors() {
        if viewModel.didStart { viewModel.setupPaywallInterceptor() }
    }

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

    func SettingsButton() -> some View {
        Button {
            router.push(.settings)
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
            !viewModel.anonymousUserId.isEmpty ||
            !viewModel.presentationId.isEmpty ||
            !viewModel.placementId.isEmpty ||
            !viewModel.contentId.isEmpty {
            Group {
                VStack(alignment: .leading, spacing: 8) {

                    if !viewModel.userId.isEmpty {
                        InfoText(observedValue: viewModel.userId, title: "User ID")
                    }
                    if !viewModel.anonymousUserId.isEmpty {
                        InfoText(observedValue: viewModel.anonymousUserId, title: "Anonymous User ID")
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
            .background(Color.brandLightGreen.opacity(0.12))
            .cornerRadius(24)
        }
    }

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
    
    private func handleDefaultDisplay() {
        // If ViewModel handled it (SDK display), we're done
        if viewModel.displayDefaultPresentation() { return }

        // Otherwise it's "Display by Sample App" — View handles SwiftUI presentation
        let mode = viewModel.displayMode
        switch mode {
        case .modal, .drawer, .popin:
            selectedSampleDisplayMode = .modal
            showingSheet = true
        case .fullscreen:
            selectedSampleDisplayMode = .fullscreen
            showingSheet = true
        case .push:
            pushPaywallIdentifier = nil
            showPushPresentation = true
        }
    }

    @ViewBuilder
    func PresentationButton() -> some View {
        Button {
            handleDefaultDisplay()
        } label: {
            // Same shape as `MainViewButton` so it can share a row with one; one line, shrunk if needed.
            Text("View Presentation")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 50)
                .bold()
                .foregroundColor(.black)
                .background(.white)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .contextMenu {
            // MARK: - Display API (async/await)
            Menu("Display API (async/await)") {
                Menu("Placement") {
                    displayModeButtons(category: .displayAsyncAwait, source: .placement)
                }
                Menu("Presentation") {
                    displayModeButtons(category: .displayAsyncAwait, source: .presentation)
                }
            }

            // MARK: - Display API (ObjC completion)
            Menu("Display API (completion)") {
                Menu("Placement") {
                    displayModeButtons(category: .displayObjC, source: .placement)
                }
                Menu("Presentation") {
                    displayModeButtons(category: .displayObjC, source: .presentation)
                }
            }

            Divider()

            // MARK: - Fetch then Display
            Menu("Fetch then Display") {
                Button("Placement") {
                    viewModel.displayPresentation(category: .fetchThenDisplay, source: .placement, displayMode: nil)
                }
                Button("Presentation") {
                    viewModel.displayPresentation(category: .fetchThenDisplay, source: .presentation, displayMode: nil)
                }
            }

            Divider()

            // MARK: - Display by Sample App (SwiftUI)
            Menu("Display by Sample App") {
                Button("Modal Sheet") {
                    selectedSampleDisplayMode = .modal
                    showingSheet = true
                }
                Button("FullScreen Cover") {
                    selectedSampleDisplayMode = .fullscreen
                    showingSheet = true
                }
                Button("Navigation Push") {
                    pushPaywallIdentifier = nil
                    showPushPresentation = true
                }

            }
        }
        .sheet(isPresented: Binding(
            get: { showingSheet && selectedSampleDisplayMode == .modal },
            set: { if !$0 { showingSheet = false } }
        ), onDismiss: restoreInterceptors) {
            PresentationContainerView()
        }
        .fullScreenCover(isPresented: Binding(
            get: { showingSheet && selectedSampleDisplayMode == .fullscreen },
            set: { if !$0 { showingSheet = false } }
        ), onDismiss: restoreInterceptors) {
            PresentationContainerView()
        }
        .navigationDestination(isPresented: $showPushPresentation) {
            if let id = pushPaywallIdentifier {
                PresentationContainerView(paywallIdentifier: id)
            } else {
                PresentationContainerView()
            }
        }
    }

    @ViewBuilder
    private func displayModeButtons(category: DisplayMethodCategory, source: SourceType) -> some View {
        Button("FullScreen") {
            viewModel.displayPresentation(category: category, source: source,
                                          displayMode: .fullScreen)
        }
        Button("Modal") {
            viewModel.displayPresentation(category: category, source: source,
                                          displayMode: .modal)
        }
        Button("Drawer (60%)") {
            viewModel.displayPresentation(category: category, source: source,
                                          displayMode: .drawer(heightPercentage: 0.6))
        }
        Button("Popin (70%)") {
            viewModel.displayPresentation(category: category, source: source,
                                          displayMode: .popin(heightPercentage: 0.7))
        }
        Button("Push") {
            viewModel.displayPresentation(category: category, source: source,
                                          displayMode: .push)
        }
    }
    
    @ViewBuilder
    func ButtonsView() -> some View {
        if let inlinePaywall = viewModel.inlinePaywall, let presentationView = inlinePaywall.presentation.swiftUIView {
            presentationView
                .frame(maxWidth: .infinity)
                .frame(height: CGFloat(inlinePaywall.presentation.height))
        }

        PresentationButton()

        Button { router.push(.deeplinks) } label: {
            MainViewButton(text: "Deeplinks")
        }.buttonStyle(.plain)

        Button { router.push(.products) } label: {
            MainViewButton(text: "Products")
        }.buttonStyle(.plain)

        Button { router.push(.dynamicOfferings) } label: {
            MainViewButton(text: "Dynamic Offerings")
        }.buttonStyle(.plain)

        ExpendableView(title: "Attributes") {
            Button { router.push(.attributes) } label: {
                MainViewButton(text: "User Attributes", defaultColor: false)
            }.buttonStyle(.plain)

            Button { router.push(.builtInAttributes) } label: {
                MainViewButton(text: "Built-in Attributes", defaultColor: false)
            }.buttonStyle(.plain)

        }

        ExpendableView(title: "SDK Public Methods") {
            Button { router.push(.directPurchase) } label: {
                MainViewButton(text: "Direct Purchase", defaultColor: false)
            }.buttonStyle(.plain)

            Button { router.push(.subscriptions) } label: {
                MainViewButton(text: "Subscriptions", defaultColor: false)
            }.buttonStyle(.plain)

            MainViewButton(text: "Synchronize/Restore", defaultColor: false)
                .onTapGesture {
                    self.viewModel.restore()
                }

            MainViewButton(text: "Restore all products", defaultColor: false)
                .onTapGesture {
                    self.viewModel.restoreAllProducts()
                }
        }

        Button { router.push(.customEvents) } label: {
            MainViewButton(text: "Custom Events")
        }.buttonStyle(.plain)

        ExpendableView(title: "Events and Logs") {
            Button { router.push(.eventsQueue) } label: {
                MainViewButton(text: "SDK events", defaultColor: false)
            }.buttonStyle(.plain)

            Button { router.push(.logs) } label: {
                MainViewButton(text: "Logs", defaultColor: false)
            }.buttonStyle(.plain)
        }

        Button { router.push(.privacy) } label: {
            MainViewButton(text: "Privacy")
        }.buttonStyle(.plain)
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
            // Collapsed, the same 50 pt as `MainViewButton`, so the two line up on a shared row.
            Text(title)
                .font(.headline)
                .foregroundColor(secondaryColor ? .white : .black)
                .frame(maxWidth: .infinity, minHeight: 50)

            if isExpanded {
                content // Displays embedded views when expanded
            }
        }
        .padding(.horizontal)
        .padding(.bottom, isExpanded ? 16 : 0)
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

    private let handleDeepLinkClosure: (URL?) -> Bool
    
    init(handleDeepLinkClosure: (@escaping (URL?) -> Bool) = { _ in false }) {
        self.handleDeepLinkClosure = handleDeepLinkClosure
        super.init()
    }

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
    }

    @discardableResult
    override func handleDeeplink(url: URL?) -> Bool {
        print("MockMainViewModel: handleDeeplink called with \(url!)")
        return handleDeepLinkClosure(url)
    }

    override func openDeeplink(url: String) {
        print("MockMainViewModel: openDeeplink called with \(url)")
    }

    override func restore() {
        print("MockMainViewModel: restore called")
    }

    override func displayPresentation(category: DisplayMethodCategory, source: SourceType, displayMode: PLYTransition?) {
        print("MockMainViewModel: displayPresentation called - category: \(category.rawValue), source: \(source.rawValue), mode: \(displayMode?.type.displayName ?? "nil")")
    }
}
