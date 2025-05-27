//
//  MainViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 18/12/2023.
//

import Foundation
import Purchasely

enum ViewState {
    case loading
    case content
    case failure(String?)
}

extension PLYAlertMessage: Identifiable {
    public var id: String { UUID().uuidString }
}

struct ParsedPurchaselyURLInfo {
    let baseURL: String          // e.g., "http://purchasely.io"
    let presentationId: String   // e.g., "TF1"
    let environment: PLYEnvironment      // Value of the 'env' query parameter
    let apiKey: String           // Value of the 'api_key' query parameter
}

class MainViewModel: ObservableObject {
    
    @Published var viewState: ViewState = .loading
    
    @Published var userId: String = ""
    @Published var presentationId: String = ""
    @Published var placementId: String = ""
    @Published var contentId: String = ""
    @Published var sdkVersion: String = ""
    @Published var displayMode: SettingsViewModel.DisplayMode = .modal
    @Published var toast: PLYToast? = nil
    
    @Published var showAlert: PLYAlertMessage?
    
    private let warningCatcher: PLYConstraintsWarningCatcher = PLYConstraintsWarningCatcher()
    
    init() {
        loadConfiguration()
        NotificationCenter.default.addObserver(self, selector: #selector(settingsUpdated), name: Notification.Name("settingsUpdated"), object: nil)
    }
    
    @objc func settingsUpdated() {
        loadConfiguration()
    }
    
    @objc func constraintBroke(obj: NSNotification) {
        SampleLogger.shared.addLog(message: "Constraint broke: \(obj)")
    }
    
    func handleScannedQRCode(code: String?) {
        // 1. Create URLComponents from the string.
        guard let urlString = code, let components = URLComponents(string: urlString) else {
            print("Error: Invalid URL string format.")
            return
        }

        // 2. Extract scheme and host for the base URL.
        guard let scheme = components.scheme, let host = components.host else {
            print("Error: URL is missing scheme or host.")
            return
        }
        let baseURL = "\(scheme)://\(host)" // e.g., "http://purchasely.io"

        // 3. Extract and validate the path components.
        // Path should be like "/ply/presentations/TF1"
        let pathComponents = components.path.split(separator: "/").map(String.init)
        // Expected structure: ["ply", "presentations", "{presentationId}"]
        guard pathComponents.count == 3,
              pathComponents[0] == "ply",
              pathComponents[1] == "presentations",
              !pathComponents[2].isEmpty else {
            print("Error: URL path does not match '/ply/presentations/{id}' format. Path: \(components.path)")
            return
        }
        let presentationId = pathComponents[2] // e.g., "TF1"

        // 4. Extract query parameters.
        guard let queryItems = components.queryItems else {
            print("Error: URL is missing query parameters.")
            return
        }

        // Find 'env' and 'api_key' values. Using first(where:) handles any order.
        guard let environment = queryItems.first(where: { $0.name == "env" })?.value, !environment.isEmpty else {
            print("Error: 'env' query parameter is missing or empty.")
            return
        }
        guard let apiKey = queryItems.first(where: { $0.name == "api_key" })?.value, !apiKey.isEmpty else {
            print("Error: 'api_key' query parameter is missing or empty.")
            return
        }

        // 5. All parts found, create and return the result struct.
        let parsedInfos = ParsedPurchaselyURLInfo(
            baseURL: baseURL,
            presentationId: presentationId,
            environment: environment == "prod" ? .prod : .staging,
            apiKey: apiKey
        )
        
        self.viewState = .loading
        Purchasely.setEnvironment(parsedInfos.environment)
        
        Purchasely.start(withAPIKey: parsedInfos.apiKey,
                         runningMode: EnvironmentRepository.shared.isObserverModeEnabled() ? .paywallObserver : .full,
                         storekitSettings: EnvironmentRepository.shared.isStorekit2Enabled() ? .storeKit2 : .storeKit1,
                         logLevel: .debug) { [self] (success, error) in
            self.viewState = success ? .content : .failure(error?.localizedDescription)
            if error != nil {
                toast = PLYToast(type: .error, title: "Error", message: "SDK Initialization failed: \(error!.localizedDescription)")
            }
            
            self.openDeeplink(url: "ply/presentations/\(parsedInfos.presentationId)")
        }
    }

    func openDeeplink(url: String) {
        guard let deeplinkURL = URL(string: "purchasely://\(url)") else { return }
        Purchasely.isDeeplinkHandled(deeplink: deeplinkURL)
    }
    
    func loadConfiguration() {
        userId = EnvironmentRepository.shared.getUserId() ?? ""
        presentationId = EnvironmentRepository.shared.getPresentationId() ?? ""
        placementId = EnvironmentRepository.shared.getPlacementId() ?? ""
        contentId = EnvironmentRepository.shared.getContentId() ?? ""
        displayMode = EnvironmentRepository.shared.getDisplayMode()
        sdkVersion = "SDK Version: \(EnvironmentRepository.shared.getPurchaselySDKVersion())"
    }
    
    func handleDeeplink(url: URL) {
        Purchasely.isDeeplinkHandled(deeplink: url)
    }
    
    func InitPurchaselySDK() {
        self.viewState = .loading

        if !EnvironmentRepository.shared.isAppAlreadyLaunched() {
            EnvironmentRepository.shared.setStorekit2Enabled(true)
            EnvironmentRepository.shared.setAppAlreadyLaunched(true)
        }

        Purchasely.addLogger(SampleLogger.shared)
        Purchasely.readyToOpenDeeplink(true)
        
        Purchasely.setUIHandler(self)
        Purchasely.setUserAttributeDelegate(self)

        Purchasely.start(withAPIKey: EnvironmentRepository.shared.getApiKey(),
                         runningMode: EnvironmentRepository.shared.isObserverModeEnabled() ? .paywallObserver : .full,
                         storekitSettings: EnvironmentRepository.shared.isStorekit2Enabled() ? .storeKit2 : .storeKit1,
                         logLevel: .debug) { [self] (success, error) in
            self.viewState = success ? .content : .failure(error?.localizedDescription)
            if error != nil {
                toast = PLYToast(type: .error, title: "Error", message: "SDK Initialization failed: \(error!.localizedDescription)")
            }
        }
        
        if let userId = EnvironmentRepository.shared.getUserId(), !userId.isEmpty {
            Purchasely.userLogin(with: userId)
        } else {
            Purchasely.userLogout()
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
}

extension MainViewModel: PLYUIHandler {
    func display(alert: PLYAlertMessage, with error: Error?, proceed: @escaping () -> ()) {
        showAlert = alert
    }
    
    func display(presentation: PLYPresentation, from sourceController: UIViewController?, proceed: @escaping () -> ()) {
        proceed()
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

