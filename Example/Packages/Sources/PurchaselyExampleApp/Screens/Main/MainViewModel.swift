//
//  MainViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 18/12/2023.
//

import Foundation
import Purchasely
import StoreKit

enum ViewState {
    case loading
    case content
    case failure(String?)
}


struct DisplayOption: Identifiable {
    let id = UUID()
    let category: DisplayMethodCategory
    let source: SourceType
    let displayMode: PLYTransition?

    var title: String {
        let modeStr = displayMode?.type.displayName ?? "SDK Default"
        return "\(category.rawValue) - \(source.rawValue) (\(modeStr))"
    }

    var shortTitle: String {
        let modeStr = displayMode?.type.displayName ?? "Default"
        return "\(source.rawValue) - \(modeStr)"
    }
}

extension PLYTransitionType {
    var displayName: String {
        switch self {
        case .fullScreen: return "FullScreen"
        case .modal: return "Modal"
        case .drawer: return "Drawer"
        case .popin: return "Popin"
        case .push: return "Push"
        case .inlinePaywall: return "Inline"
        @unknown default: return "Unknown"
        }
    }
}

extension PLYAlertMessage: @retroactive Identifiable {
    /// MUST be stable per case — do NOT go back to `UUID()`.
    ///
    /// `.alert(item:)` identifies the alert it is presenting by this `id`, and re-reads it on
    /// every re-render of the view. A freshly generated id meant the presented alert never
    /// compared equal to itself, so any re-render while an alert was on screen made SwiftUI
    /// dismiss it and present a new one — the alert visibly closed and reopened on its own.
    /// `PLYAlertMessage` is an `@objc enum: Int`, so `rawValue` is the natural stable identity.
    public var id: Int { rawValue }
}

class MainViewModel: ObservableObject {
    
    struct InlinePaywall {
        let presentation: PLYPresentation
    }
    
    @Published var viewState: ViewState = .loading
    
    @Published var userId: String = ""
    @Published var anonymousUserId: String = ""
    @Published var presentationId: String = ""
    @Published var placementId: String = ""
    @Published var contentId: String = ""
    @Published var sdkVersion: String = ""
    @Published var displayMode: DisplayMode = .modal
    @Published var toast: PLYToast? = nil
    @Published var displayedBySample: Bool = false
    @Published var showAlert: PLYAlertMessage?
    // Some alerts (e.g. redemption expired) carry their body in the `error` rather than in
    // `PLYAlertMessage.content` — that's how the email_hint-templated string rides in. Mirror
    // the SDK's own renderer (`content ?? error?.localizedDescription`) by keeping the error
    // message alongside the alert.
    @Published var alertErrorMessage: String?

    @Published var inlinePaywall: InlinePaywall? = nil
    
    @Published var didStart: Bool = false

    private var restarting: Bool = false
    
    private let warningCatcher: PLYConstraintsWarningCatcher = PLYConstraintsWarningCatcher()

    /// Receives `PLYWebRedemptionDelegate` callbacks for `{scheme}://ply/redeem/{token}` links.
    ///
    /// Stored, not inlined into the start chain: the SDK holds the delegate **weakly**, so a
    /// `.webRedemptionDelegate(SampleWebRedemptionDelegate())` written inline would be deallocated
    /// the moment `start()` finished applying it, and no callback would ever arrive. The app is the
    /// owner. Its handler is wired in `init`, before either start chain can run.
    private let webRedemptionDelegate = SampleWebRedemptionDelegate()
    
    init() {
        loadConfiguration()
        NotificationCenter.default.addObserver(self, selector: #selector(settingsUpdated), name: Notification.Name("settingsUpdated"), object: nil)
        webRedemptionDelegate.onCompleted = { [weak self] result in
            self?.showWebRedemptionResult(result)
        }
    }

    /// What an integrator would actually do from `webRedemptionCompleted` — on success, run the
    /// onboarding the grant unlocks; on failure, surface the outcome so a tester can see the
    /// callback fired without reading the SDK log.
    ///
    /// The SDK guarantees this runs on the main thread, and after the matching
    /// `REDEMPTION_CONSUMED` / `REDEMPTION_FAILED` event, so touching `@Published` state directly
    /// is safe — no dispatch needed.
    private func showWebRedemptionResult(_ result: PLYWebRedemptionResult) {
        switch result.asResult() {
        case .success(let context, let replay):
            let subscription = context?.subscription
            // `subscription` is nil when the 200 carried none — still a success, the receipt
            // validated and entitlements refreshed.
            let granted = subscription.map { "\($0.product.vendorId) / \($0.plan.vendorId)" }
                ?? "no subscription in the payload"
            SampleLogger.shared.addLog(
                message: "[Sample][WebRedemptionDelegate] success — replay=\(replay), granted=\(granted)")
            // The grant may have changed what the user owns; refresh the id line like the
            // deeplink path does.
            refreshAnonymousUserId()
            // What the delegate exists for: react to the grant with real UI. Rather than a toast,
            // fetch and display the post-redemption placement — the "present a dedicated screen
            // or run a tailored onboarding" case the SDK-side commit calls out.
            displayWebRedemptionCompletedPlacement()

        case .failure(let errorCode, let errorMessage):
            SampleLogger.shared.addLog(
                message: "[Sample][WebRedemptionDelegate] failure — code=\(errorCode ?? "none"), message=\(errorMessage ?? "none")")
            toast = PLYToast(
                type: .error,
                title: "Sample · redemption failed",
                message: "From the SAMPLE APP's PLYWebRedemptionDelegate — \(errorCode ?? "no error code"): \(errorMessage ?? "no message")"
            )
        }
    }

    /// Placement displayed when a web redemption settles successfully. Swap the id here if the
    /// Console names it differently.
    private static let webRedemptionCompletedPlacementId = "web_redemption_completed"

    /// Fetch-then-display of the post-redemption placement.
    ///
    /// Deliberately fetched here rather than pre-warmed: the grant is what makes this placement
    /// worth showing, and the fetch has to happen after it so the backend targets the user who
    /// now owns the subscription.
    ///
    /// Failures stay local (log + toast) on purpose: unlike `showError`, a paywall that fails to
    /// load must not flip the whole main screen into `.failure` — the redemption itself
    /// succeeded.
    private func displayWebRedemptionCompletedPlacement() {
        let placementId = Self.webRedemptionCompletedPlacementId
        SampleLogger.shared.addLog(
            message: "[Sample][WebRedemptionDelegate] fetching placement \"\(placementId)\"")
        Task { @MainActor [weak self] in
            let request = PLYPresentationBuilder
                .forPlacementId(placementId)
                .onDismissed { outcome in Self.logDismiss(outcome) }
                .build()
            do {
                let presentation = try await request.preload()
                guard presentation.swiftUIView != nil else {
                    self?.reportRedemptionPlacementFailure("no view available for placement \"\(placementId)\"")
                    return
                }
                SampleLogger.shared.addLog(
                    message: "[Sample][WebRedemptionDelegate] placement \"\(placementId)\" loaded (\(presentation.screenId)) — displaying")
                presentation.display(from: nil)
            } catch {
                self?.reportRedemptionPlacementFailure(
                    "placement \"\(placementId)\" failed: \(error.localizedDescription)")
            }
        }
    }

    private func reportRedemptionPlacementFailure(_ message: String) {
        SampleLogger.shared.addLog(message: "[Sample][WebRedemptionDelegate] \(message)")
        toast = PLYToast(type: .error, title: "Sample · redemption paywall", message: message)
    }

    @objc func settingsUpdated() {
        loadConfiguration()
    }
    
    @objc func constraintBroke(obj: NSNotification) {
        SampleLogger.shared.addLog(message: "Constraint broke: \(obj)")
    }
    
    private func setupActionInterceptors() {
        let observerMode = EnvironmentRepository.shared.isObserverModeEnabled()

        // Intercept the tap on login
        Purchasely.interceptAction(.login) { info, params, completion in
            // When the user has completed the process
            // Pass .notHandled to let the SDK reload the paywall (reflects updated subscription state)
            completion(.notHandled)
        }

        Purchasely.interceptAction(.close) { info, params, completion in
            completion(.notHandled)
        }

        Purchasely.interceptAction(.navigate) { info, params, completion in
            completion(.notHandled)
        }

        Purchasely.interceptAction(.purchase) { [weak self] info, params, completion in
            guard let self else {
                completion(.failed)
                return
            }
            guard let plan = params?.plan,
                  let appleProductId = plan.appleProductId else {
                completion(.failed)
                return
            }

            if observerMode {
                self.storeKit2PurchaseProcess(appleProductId: appleProductId,
                                              promoOffer: params?.promoOffer,
                                              interceptorInfo: info,
                                              completion: completion)
            } else {
                completion(.notHandled)
            }
        }

        Purchasely.interceptAction(.closeAll) { info, params, completion in
            completion(.notHandled)
        }

        Purchasely.interceptAction(.openPlacement) { info, params, completion in
            completion(.notHandled)
        }
    }
    
    // MARK: - Display Methods

    /// Quick display using the saved settings (method, source, display mode).
    /// Returns `true` if handled by the ViewModel (SDK display).
    /// Returns `false` if the View should handle it (Sample App display).
    @discardableResult
    func displayDefaultPresentation() -> Bool {
        let method = EnvironmentRepository.shared.getDisplayMethod()
        guard method != .sampleApp else { return false }

        let source = resolvedSource()
        let displayMode: PLYTransition?
        switch method {
        case .displayAsyncAwait, .displayObjC:
            displayMode = defaultPLYTransition()
        case .fetchThenDisplay:
            displayMode = nil
        case .sampleApp:
            return false
        }

        displayPresentation(category: method, source: source, displayMode: displayMode)
        return true
    }

    private func resolvedSource() -> SourceType {
        switch EnvironmentRepository.shared.getSourcePreference() {
        case .placement: return .placement
        case .presentation: return .presentation
        case .auto:
            let placementId = EnvironmentRepository.shared.getPlacementId()
            return (placementId != nil && !placementId!.isEmpty) ? .placement : .presentation
        }
    }

    private func defaultPLYTransition() -> PLYTransition {
        switch EnvironmentRepository.shared.getDisplayMode() {
        case .modal: return .modal
        case .fullscreen: return .fullScreen
        case .push: return .push
        case .drawer: return .drawer(heightPercentage: 0.6)
        case .popin: return .popin(heightPercentage: 0.7)
        }
    }

    func displayPresentation(category: DisplayMethodCategory, source: SourceType, displayMode: PLYTransition?) {
        let placementId = EnvironmentRepository.shared.getPlacementId()
        let presentationId = EnvironmentRepository.shared.getPresentationId()
        let contentId = EnvironmentRepository.shared.getContentId()

        SampleLogger.shared.addLog(message: "[\(category.rawValue)] Starting with source: \(source.rawValue), mode: \(displayMode?.type.displayName ?? "nil")")

        switch category {
        case .displayAsyncAwait:
            displayWithAsyncAwait(source: source, placementId: placementId, presentationId: presentationId, displayMode: displayMode)
        case .displayObjC:
            displayWithObjC(source: source, placementId: placementId, presentationId: presentationId, displayMode: displayMode)
        case .fetchThenDisplay:
            fetchThenDisplay(source: source, placementId: placementId, presentationId: presentationId, contentId: contentId)
        case .sampleApp:
            break
        }
    }

    func setupPaywallInterceptor() {
        setupActionInterceptors()
    }

    private static func logDismiss(_ outcome: PLYPresentationOutcome) {
        switch outcome.purchaseResult {
        case .purchased:
            SampleLogger.shared.addLog(message: "[onDismissed] PURCHASED")
        case .restored:
            SampleLogger.shared.addLog(message: "[onDismissed] RESTORED")
        case .cancelled:
            SampleLogger.shared.addLog(message: "[onDismissed] CANCELLED")
        case .none:
            SampleLogger.shared.addLog(message: "[onDismissed] NO PURCHASE")
        @unknown default:
            SampleLogger.shared.addLog(message: "[onDismissed] UNKNOWN")
        }
    }

    private func showError(_ message: String) {
        SampleLogger.shared.addLog(message: "[Error] \(message)")
        self.viewState = .failure(message)
        self.toast = PLYToast(type: .error, title: "Error", message: message)
    }

    // MARK: - Display API (async/await)

    private func displayWithAsyncAwait(source: SourceType, placementId: String?, presentationId: String?, displayMode: PLYTransition?) {
        guard let mode = displayMode else {
            showError("Display mode is required for Display API")
            return
        }

        Task { @MainActor in
            do {
                let presentationRequest: PLYPresentationRequest

                switch (source, presentationId) {
                case (.placement, _):
                    guard let placementId = placementId, !placementId.isEmpty else {
                        showError("Placement ID is required. Please set it in Settings.")
                        return
                    }
                    SampleLogger.shared.addLog(message: "[Display async/await] Calling Purchasely.display(for: \"\(placementId)\", displayMode: \(mode.type.displayName))")
                    presentationRequest = PLYPresentationBuilder
                        .forPlacementId(placementId)
                        .build()

                case (.presentation, let presentationId?) where !presentationId.isEmpty,
                  (.auto, let presentationId?) where !presentationId.isEmpty:
                  presentationRequest = PLYPresentationBuilder
                      .from(screenId: presentationId)
                      .build()
                    SampleLogger.shared.addLog(message: "[Display async/await] Calling Purchasely.display(with: \"\(presentationId)\", displayMode: \(mode.type.displayName))")
                  
                case (.presentation, _), (.auto, _) :
                  presentationRequest = PLYPresentationBuilder
                      .build()
                    SampleLogger.shared.addLog(message: "[Display async/await] Calling Purchasely.display(with: \"nil\", displayMode: \(mode.type.displayName))")
                }
              
                let presentation = try await presentationRequest.display(transition: mode)

                SampleLogger.shared.addLog(message: "[Display async/await] Presentation loaded: \(presentation.screenId)")
            } catch {
                SampleLogger.shared.addLog(message: "[Display async/await] Error: \(error.localizedDescription)")
                showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Display API (ObjC completion)

    private func displayWithObjC(source: SourceType, placementId: String?, presentationId: String?, displayMode: PLYTransition?) {
        guard let mode = displayMode else {
            showError("Display mode is required for Display API")
            return
        }

        let presentationRequest: PLYPresentationRequest
        switch (source, presentationId) {
        case (.placement, _):
            guard let placementId = placementId, !placementId.isEmpty else {
                showError("Placement ID is required. Please set it in Settings.")
                return
            }
            SampleLogger.shared.addLog(message: "[Display ObjC] Calling Purchasely.display(for: \"\(placementId)\", displayMode: \(mode.type.displayName), completion:)")
            presentationRequest = PLYPresentationBuilder.from(placementId: placementId)
                .build()

        case (.presentation, let presentationId?) where !presentationId.isEmpty, (.auto, let presentationId?) where !presentationId.isEmpty:
            SampleLogger.shared.addLog(message: "[Display ObjC] Calling Purchasely.display(with: \"\(presentationId)\", displayMode: \(mode.type.displayName), completion:)")
            presentationRequest = PLYPresentationBuilder
                .from(screenId: presentationId)
                .build()
        case (.presentation, _), (.auto, _):
            SampleLogger.shared.addLog(message: "[Display ObjC] Calling Purchasely.display(with: \"nil\", displayMode: \(mode.type.displayName), completion:)")
            presentationRequest = PLYPresentationBuilder
                .build()
        }
      
        presentationRequest.display(transition: mode) { [weak self] presentation, error in
            if let error = error {
                self?.showError(error.localizedDescription)
            } else {
                SampleLogger.shared.addLog(message: "[Display ObjC] Presentation loaded: \(presentation?.screenId ?? "nil")")
            }
        }
    }

    // MARK: - Fetch then Display

    private func fetchThenDisplay(source: SourceType, placementId: String?, presentationId: String?, contentId: String?) {
      Task { @MainActor [weak self] in
        let presentationRequest: PLYPresentationRequest
        switch (source, presentationId) {
        case (.placement, _):
            guard let placementId = placementId, !placementId.isEmpty else {
                showError("Placement ID is required. Please set it in Settings.")
                return
            }
            SampleLogger.shared.addLog(message: "[Fetch then Display] Building PLYPresentationBuilder.forPlacementId(\"\(placementId)\")")
            let presentationBuilder = PLYPresentationBuilder.forPlacementId(placementId)
            if let contentId {
                _ = presentationBuilder.contentId(contentId)
            }
            presentationRequest = presentationBuilder
                .onDismissed { outcome in Self.logDismiss(outcome) }
                .build()

        case (.presentation, let presentationId?) where !presentationId.isEmpty, (.auto, let presentationId?) where !presentationId.isEmpty:
            SampleLogger.shared.addLog(message: "[Fetch then Display] Building PLYPresentationBuilder.forScreenId(\"\(presentationId)\")")
            let presentationBuilder = PLYPresentationBuilder.forScreenId(presentationId)
            if let contentId {
                _ = presentationBuilder.contentId(contentId)
            }
            presentationRequest = presentationBuilder
                .onDismissed { outcome in Self.logDismiss(outcome) }
                .build()
        case (.presentation, _), (.auto, _):
            SampleLogger.shared.addLog(message: "[Fetch then Display] Building PLYPresentationBuilder.default()")
            let presentationBuilder = PLYPresentationBuilder.default()
            if let contentId {
                _ = presentationBuilder.contentId(contentId)
            }
            presentationRequest = presentationBuilder
                .onDismissed { outcome in Self.logDismiss(outcome) }
                .build()
        }
        do {
          let presentation = try await presentationRequest.preload()
          
          guard presentation.swiftUIView != nil else {
              self?.showError("No view available")
              return
          }
          let info = PresentationInfo(presentation).rows.map { "\($0.0)=\($0.1)" }.joined(separator: ", ")
          SampleLogger.shared.addLog(message: "[Fetch then Display] \(info)")
          SampleLogger.shared.addLog(message: "[Fetch then Display] Calling presentation.display(from: nil)")
          presentation.display(from: nil)
        } catch {
          self?.showError("[Fetch] \(error.localizedDescription)")
        }
      }
    }

    // MARK: - Legacy method (kept for backward compatibility)

    func loadPresentation() {
        // Default behavior: fetch then display using placement if available, otherwise presentation
        let placementId = EnvironmentRepository.shared.getPlacementId()
        let source: SourceType = (placementId != nil && !placementId!.isEmpty) ? .placement : .presentation
        fetchThenDisplay(source: source,
                         placementId: placementId,
                         presentationId: EnvironmentRepository.shared.getPresentationId(),
                         contentId: EnvironmentRepository.shared.getContentId())
    }

        func openDeeplink(url: String) {
        guard !restarting else { return }
        guard let deeplinkURL = URL(string: url) else { return }

        self.viewState = .loading

        let parsedInfos = PurchaselyDeeplinkParser.parse(url)

        if parsedInfos?.deeplinkPath == "presentations",
           let presentationId = parsedInfos?.presentationId {
            EnvironmentRepository.shared.setPresentationId(presentationId)
            self.presentationId = presentationId
        }

        // Only `api_key` reconfigures the sample. Without it, hand the link to the SDK as is.
        guard let parsedInfos = parsedInfos, let newApiKey = parsedInfos.apiKey else {
            if self.handleDeeplink(url: deeplinkURL) {
                self.viewState = .content
            } else {
                self.viewState = .failure("Deeplink not handled")
            }
            return
        }

        SampleLogger.shared.addLog(message: "[Deeplink] api_key=\(newApiKey.prefix(8))…, path=\(parsedInfos.deeplinkPath), auid=\(parsedInfos.auid != nil ? "present" : "absent") — restarting SDK")
        EnvironmentRepository.shared.setApiKey(newApiKey)

        self.restarting = true
        self.didStart = false

        // Armed before `start` so the buffer and the os_log mirror catch SDK startup itself.
        // Idempotent.
        SampleLogger.install()

        Purchasely
            .apiKey(newApiKey)
            .runningMode(EnvironmentRepository.shared.isObserverModeEnabled() ? .observer : .full)
            .storekitSettings(EnvironmentRepository.shared.isStorekit2Enabled() ? .storeKit2 : .storeKit1)
            .logLevel(.debug)
            .webRedemptionDelegate(webRedemptionDelegate, appHandlesRedemptionAlert: false)
            .start { [self] error in
                self.viewState = error == nil ? .content : .failure(error?.localizedDescription)

                if let error {
                    toast = PLYToast(
                        type: .error,
                        title: "Error",
                        message: "SDK Initialization failed: \(error.localizedDescription)"
                    )
                }

                self.restarting = false
                self.didStart = true
                self.refreshAnonymousUserId()
                Purchasely.allowCampaigns(EnvironmentRepository.shared.isAllowCampaignsEnabled())

                // Hand the SDK the ORIGINAL URL minus the sample's own `api_key`, so every
                // FUNCTIONAL param (`preview`, `theme_mode`, `language`, `auid`) survives.
                let sdkURL = PurchaselyDeeplinkParser.urlStrippedOfConfigParams(url)

                // Never log the URL for redeem — its PATH carries the bearer token.
                let restartPrefix = "[Deeplink] SDK restarted: api_key=\(newApiKey.prefix(8))…, error=\(error.map { $0.localizedDescription } ?? "none")"
                if parsedInfos.deeplinkPath == "redeem" {
                    SampleLogger.shared.addLog(message: "\(restartPrefix) — re-handling redeem deeplink")
                } else {
                    SampleLogger.shared.addLog(message: "\(restartPrefix) — re-handling \(sdkURL?.absoluteString ?? "nil")")
                }
                _ = self.handleDeeplink(url: sdkURL)
                Purchasely.setCustomScreenViewControllerDelegate(CustomScreenViewControllerDelegate())
                Purchasely.setCustomScreenViewDelegate(CustomScreenViewDelegate())
            }
    }

    func loadConfiguration() {
        userId = EnvironmentRepository.shared.getUserId() ?? ""
        presentationId = EnvironmentRepository.shared.getPresentationId() ?? ""
        placementId = EnvironmentRepository.shared.getPlacementId() ?? ""
        contentId = EnvironmentRepository.shared.getContentId() ?? ""
        displayMode = EnvironmentRepository.shared.getDisplayMode()
        sdkVersion = "SDK Version: \(EnvironmentRepository.shared.getPurchaselySDKVersion())"
        displayedBySample = EnvironmentRepository.shared.getDisplayedBySample()
    }
    
    @discardableResult
    func handleDeeplink(url: URL?) -> Bool {
        guard let url = url else { return false }
        let handled = Purchasely.handleDeeplink(url)
        // A redemption deeplink may have just adopted/replaced the anonymous id — refresh the
        // info line. (Slightly deferred: begin-time adoption of a queued deeplink runs async.)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshAnonymousUserId()
        }
        return handled
    }

    /// Refresh the displayed anonymous user id. Guarded by `didStart`: the SDK getter
    /// GENERATES an id on first read, and the sample must never trigger that before `start()`
    /// (it would defeat the redemption deeplink's auid adoption we display this line to verify).
    func refreshAnonymousUserId() {
        guard didStart else { return }
        anonymousUserId = Purchasely.anonymousUserId
    }
    
    func InitPurchaselySDK() {
        self.viewState = .loading
        
        if !EnvironmentRepository.shared.isAppAlreadyLaunched() {
            EnvironmentRepository.shared.setStorekit2Enabled(true)
            EnvironmentRepository.shared.setAppAlreadyLaunched(true)
        }
        
        // Re-apply the language picked in Settings: the SDK holds it in memory only, so without this
        // a forced language would silently revert to the device language on relaunch.
        EnvironmentRepository.shared.applySelectedLanguageToSDK()

        // Since v6, deeplinks are allowed by default — no explicit Purchasely.allowDeeplink(true)
        // is needed. To withhold them until later, add `.allowDeeplink(false)` to the chain below.

        Purchasely.setUIHandler(self)
        Purchasely.setUserAttributeDelegate(self)
        Purchasely.setEventDelegate(SDKEventLog.shared)
        self.didStart = false
        // Armed before `start` so the buffer and the os_log mirror catch SDK startup itself —
        // registration used to happen only when the Logs screen appeared, which dropped
        // everything before that. Idempotent.
        SampleLogger.install()

        Purchasely
            .apiKey(EnvironmentRepository.shared.getApiKey())
            .runningMode(EnvironmentRepository.shared.isObserverModeEnabled() ? .observer : .full)
            .storekitSettings(EnvironmentRepository.shared.isStorekit2Enabled() ? .storeKit2 : .storeKit1)
            .logLevel(.debug)
            // `appHandlesRedemptionAlert: false` is the SDK default, spelled out to document it.
            // The SDK presents its own terminal popin, and the delegate fires once the user taps
            // OK. Pass `true` to suppress the popin and be called as soon as the redemption settles.
            .webRedemptionDelegate(webRedemptionDelegate, appHandlesRedemptionAlert: false)
            .start { [self] error in
                self.viewState = error == nil ? .content : .failure(error?.localizedDescription)
                if let error {
                    toast = PLYToast(type: .error, title: "Error", message: "SDK Initialization failed: \(error.localizedDescription)")
                }
                self.didStart = true
                self.refreshAnonymousUserId()
                Purchasely.setDebugMode(enabled: true)
                Purchasely.allowCampaigns(EnvironmentRepository.shared.isAllowCampaignsEnabled())
                Purchasely.setCustomScreenViewControllerDelegate(CustomScreenViewControllerDelegate())
                Purchasely.setCustomScreenViewDelegate(CustomScreenViewDelegate())

                setupPaywallInterceptor()

                fetchInlinePaywall()
            }

        if let userId = EnvironmentRepository.shared.getUserId(), !userId.isEmpty {
            Purchasely.userLogin(with: userId)
        } else {
            Purchasely.userLogout()
        }
    }
    
    // TODO: reset and refetch inline paywall when API key changes
    func fetchInlinePaywall() {
        Task { @MainActor [weak self] in
            do {
                let presentation = try await PLYPresentationBuilder
                    .forPlacementId("DO_NOT_TOUCH")
                    .build()
                    .preload()
                self?.inlinePaywall = InlinePaywall(presentation: presentation)
            } catch {
                // Inline paywall is optional; ignore fetch errors.
            }
        }
    }
    
    func restore() {
        self.viewState = .loading
        Purchasely.synchronize {
            self.viewState = .content
        } failure: { error in
            self.viewState = .content
        }
    }
    
    func restoreAllProducts() {
        self.viewState = .loading
        Purchasely.restoreAllProducts {
            self.viewState = .content
            self.toast = PLYToast(type: .success, title: "Restore", message: "Purchases restored")
        } failure: { error in
            self.viewState = .content
            self.toast = PLYToast(type: .error, title: "Restore failed", message: error.localizedDescription)
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private func storeKit2PurchaseProcess(appleProductId: String,
                                          promoOffer: PLYPromoOffer?,
                                          interceptorInfo: PLYInterceptorInfo?,
                                          completion: @escaping (PLYInterceptResult) -> Void) {
        Task { [weak self] in
            guard let `self` = self else {
                DispatchQueue.main.async { completion(.failed) }
                return
            }
            SampleLogger.shared.addLog(message: "[StoreKit2][Observer Mode] Purchasing \(appleProductId)")
            let purchased: Bool
            do {
                purchased = try await self.purchaseWithStoreKit2(for:appleProductId,
                                                                 with: promoOffer?.storeOfferId,
                                                                 interceptorInfo: interceptorInfo,
                                                                 completion: completion)
            } catch {
                // The purchase never reached a result: tell the SDK, exactly once.
                SampleLogger.shared.addLog(message: "[StoreKit2][Observer Mode] error with purchasing with StoreKit2: \(error)")
                DispatchQueue.main.async { completion(.failed) }
                return
            }
            if purchased {
                do {
                    try await Purchasely.syncPurchase(for: appleProductId)
                } catch {
                    SampleLogger.shared.addLog(message: "[StoreKit2][Observer Mode] syncPurchase failed: \(error)")
                }
            }
        }
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func purchaseWithStoreKit2(for appleProductId: String,
                               with promoOfferId: String?,
                               interceptorInfo: PLYInterceptorInfo?,
                               completion: @escaping (PLYInterceptResult) -> Void) async throws -> Bool {

        // Every path below calls `completion` exactly once, on the main queue. A path that throws
        // before any `completion` call leaves it to the caller's `catch`.
        func finish(_ result: PLYInterceptResult, after: (() -> Void)? = nil) {
            DispatchQueue.main.async {
                completion(result)
                after?()
            }
        }

        if let promoOfferId = promoOfferId {

            // Token-aware signing: the token returned here goes unchanged into `appAccountToken`.
            Purchasely.signPromotionalOffer(storeProductId: appleProductId,
                                            storeOfferId: promoOfferId,
                                            purchaseContextToken: nil) { signature, token in

                guard let decodedSignature = Data(base64Encoded: signature.signature) else {
                    finish(.failed)
                    return
                }

                Task {
                    do {
                        var options: Set<Product.PurchaseOption> = []
                        options.insert(.appAccountToken(token))
                        options.insert(.promotionalOffer(offerID: signature.identifier,
                                                         keyID: signature.keyIdentifier,
                                                         nonce: signature.nonce,
                                                         signature: decodedSignature,
                                                         timestamp: Int(signature.timestamp)))

                        guard let product = try await Product.products(for: [appleProductId]).first else {
                            finish(.failed)
                            return
                        }
                        switch try await product.purchase(options: options) {
                        case .userCancelled, .pending:
                            SampleLogger.shared.addLog(message: "Purchase with promo offer: userCancelled")
                            finish(.success)
                        case .success(.unverified(_, let error)):
                            SampleLogger.shared.addLog(message: "Purchase with promo offer: unverified \(error.localizedDescription)")
                            finish(.success)
                        case .success(.verified(let transaction)):
                            SampleLogger.shared.addLog(message: "Purchase with promo offer: verified")
                            await transaction.finish()
                            finish(.success) { interceptorInfo?.controller?.dismiss(animated: true) }
                        @unknown default:
                            finish(.failed)
                        }
                        await MainActor.run { self.viewState = .content }
                    } catch {
                        SampleLogger.shared.addLog(message: "Purchase with promo offer failed: \(error)")
                        finish(.failed)
                    }
                }
            } failure: { error in
                DispatchQueue.main.async { self.viewState = .failure(error.localizedDescription) }
                finish(.failed)
            }
            return false
        }

        guard let product = try await Product.products(for: [appleProductId]).first else {
            finish(.failed)
            return false
        }
        let purchased: Bool
        switch try await product.purchase() {
        case .userCancelled, .pending:
            SampleLogger.shared.addLog(message: "Purchase: userCancelled")
            finish(.success)
            purchased = false
        case .success(.unverified(_, let error)):
            SampleLogger.shared.addLog(message: "Purchase: unverified \(error.localizedDescription)")
            finish(.success)
            purchased = false
        case .success(.verified(let transaction)):
            SampleLogger.shared.addLog(message: "Purchase: verified")
            await transaction.finish()
            finish(.success) { Purchasely.closeAllScreens() }
            purchased = true
        @unknown default:
            finish(.failed)
            purchased = false
        }
        await MainActor.run { self.viewState = .content }
        return purchased
    }

}

extension MainViewModel: PLYUIHandler {
    func display(alert: PLYAlertMessage, with error: Error?, proceed: @escaping () -> ()) {
        // Set the error message BEFORE the item so it's ready when `.alert(item:)` presents.
        alertErrorMessage = error?.localizedDescription
        if showAlert != nil {
            // An alert is already on screen (e.g. the user left "token expired" open and tapped
            // another redeem link). SwiftUI's `.alert(item:)` doesn't reliably swap the presented
            // alert when the item changes — dismiss first, then present the new one next runloop.
            showAlert = nil
            DispatchQueue.main.async { self.showAlert = alert }
        } else {
            showAlert = alert
        }
    }
    
    func display(presentation: PLYPresentation, from sourceController: UIViewController?, proceed: @escaping () -> ()) {
        proceed()
    }
}

/// Bridges the SDK's Web2App settlement callback to `MainViewModel`.
///
/// A separate `NSObject` on purpose. `PLYWebRedemptionDelegate` declares
/// `webRedemptionCompleted(result:)` as a **required** `@objc` member, and a required `@objc`
/// requirement needs an `@objc` witness — which a plain Swift class cannot provide.
/// `MainViewModel` conforms to `PLYUIHandler` and `PLYUserAttributeDelegate` directly only because
/// every member of those two is `@objc optional`, so there is nothing to witness. Making
/// `MainViewModel` an `NSObject` subclass just for this would be the wrong trade in a SwiftUI
/// `ObservableObject`; a four-line adapter is not.
final class SampleWebRedemptionDelegate: NSObject, PLYWebRedemptionDelegate {

    /// Set by the owner. Called on the main thread, once per settled redemption.
    var onCompleted: ((PLYWebRedemptionResult) -> Void)?

    func webRedemptionCompleted(result: PLYWebRedemptionResult) {
        onCompleted?(result)
    }
}

extension MainViewModel: PLYUserAttributeDelegate {
    func onUserAttributeRemoved(key: String, source: PLYUserAttributeSource) {
        print("onUserAttributeRemoved: \(key) \(source)")
    }
    
    func onUserAttributeSet(key: String, type: PLYUserAttributeType, value: Any?, source: PLYUserAttributeSource) {
        print("onUserAttributeSet: \(key) \(type) \(String(describing: value)) \(source)")
    }
}

internal extension Notification.Name {
    static let willBreakConstraint = Notification.Name(
        rawValue: "NSISEngineWillBreakConstraint"
    )
}

internal final class PLYConstraintsWarningCatcher {
    
    var alreadyRunning: Bool = false
    internal static var originalImplementation: IMP?
    
    init() {
        startListening()
    }
    
    func startListening() {
        guard !alreadyRunning else { return }
        
        alreadyRunning = true
        
        let selector = NSSelectorFromString("engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:")
        
        guard let method = class_getInstanceMethod(UIView.self, selector) else { return }
        
        // Store the original method implementation
        PLYConstraintsWarningCatcher.originalImplementation = method_getImplementation(method)
        
        let swizzledSelector = #selector(UIView.willBreakConstraintSwizzled(_:_:_:))
        
        guard let swizzledMethod = class_getInstanceMethod(UIView.self, swizzledSelector) else { return }
        
        let swizzledImplementation = method_getImplementation(swizzledMethod)
        
        // Swizzle methods
        class_replaceMethod(UIView.self,
                            selector,
                            swizzledImplementation,
                            method_getTypeEncoding(swizzledMethod))
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveBrokenConstraintNotification),
            name: .willBreakConstraint,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didReceiveBrokenConstraintNotification(notification: NSNotification) {
        guard let constraint = notification.object as? NSLayoutConstraint else {
            return
        }
        SampleLogger.shared.addLog(message: "Constraint broke: \(constraint)")
    }
}

internal extension UIView {
    @objc func willBreakConstraintSwizzled(_ engine: Any, _ constraint: NSLayoutConstraint, _ conflict: Any) {
        // Call the original method manually
        if let originalIMP = PLYConstraintsWarningCatcher.originalImplementation {
            typealias OriginalMethod = @convention(c) (UIView, Selector, Any, NSLayoutConstraint, Any) -> Void
            let originalFunction = unsafeBitCast(originalIMP, to: OriginalMethod.self)
            originalFunction(self, NSSelectorFromString("engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:"), engine, constraint, conflict)
        }
        
        // Send a notification
        NotificationCenter.default.post(
            name: .willBreakConstraint,
            object: constraint
        )
    }
}

