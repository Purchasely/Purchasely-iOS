//  PurchaselyDeeplinkParser.swift
//
//  Parses a Purchasely deeplink (custom scheme or universal link) into its parts. Pure: no
//  @Published state, no SDK side effects. The sample only honors `api_key`; it never accepts an
//  environment or a custom host from a link.

import Foundation

public struct ParsedPurchaselyURLInfo {
    public let baseURL: String          // e.g., "purchasely://ply"
    public let deeplinkPath: String
    public let presentationId: String   // e.g., "TF1" — or the redemption token for "redeem"
    public let apiKey: String?          // Value of the 'api_key' query parameter
    public let auid: String?            // Value of the 'auid' query parameter (redeem only)

    public init(baseURL: String, deeplinkPath: String, presentationId: String,
                apiKey: String?, auid: String? = nil) {
        self.baseURL = baseURL
        self.deeplinkPath = deeplinkPath
        self.presentationId = presentationId
        self.apiKey = apiKey
        self.auid = auid
    }
}

public enum PurchaselyDeeplinkParser {

    /// Query parameters the SAMPLE consumes. `api_key` reconfigures the sample and is hidden from
    /// the SDK. The parser reads no other configuration from a link: no environment, no host.
    ///
    /// Everything else on a Purchasely deeplink is FUNCTIONAL and belongs to the SDK:
    /// `preview`, `theme_mode`, `language`, `auid`, and whatever the Console adds next.
    public static let configParamNames: Set<String> = ["api_key"]

    /// The original URL with `configParamNames` stripped and every other query parameter
    /// preserved, or nil if the URL cannot be parsed.
    ///
    /// Note `redeem` carries its bearer token in the PATH, not the query, so this returns a URL
    /// that still contains it — callers must keep the existing "never log a redeem URL" rule.
    public static func urlStrippedOfConfigParams(_ url: String?) -> URL? {
        guard let urlString = url, var components = URLComponents(string: urlString) else {
            return nil
        }
        let kept = (components.queryItems ?? []).filter { !configParamNames.contains($0.name) }
        // nil, not [], so a fully-stripped URL has no trailing "?" — the SDK's `fromURL` regexes
        // distinguish `ply/presentations/{id}` from `ply/presentations/{id}?…` and a bare "?"
        // would wrongly select the `previewWithParams` branch.
        components.queryItems = kept.isEmpty ? nil : kept
        return components.url
    }

    /// Parse a Purchasely deeplink into its parts, or nil if it doesn't match. Accepts:
    ///   - purchasely://ply/presentations/{id}?api_key=X   (custom scheme)
    ///   - https://purchasely.io/ply/presentations/{id}?...      (universal link)
    public static func parse(_ url: String?) -> ParsedPurchaselyURLInfo? {
        guard let urlString = url, let components = URLComponents(string: urlString) else {
            print("Error: Invalid URL string format.")
            return nil
        }

        let baseURL: String
        let pathComponents: [String]

        if components.scheme == "purchasely", components.host == "ply" {
            baseURL = "purchasely://ply"
            pathComponents = components.path.split(separator: "/").map(String.init)
        } else if (components.scheme == "https" || components.scheme == "http"),
                  let host = components.host,
                  host == "purchasely.io" || host.hasSuffix(".purchasely.io")
                    || host == "purchasely.com" || host.hasSuffix(".purchasely.com") {
            let allComponents = components.path.split(separator: "/").map(String.init)
            guard allComponents.first == "ply" else {
                print("Error: Universal link path does not start with '/ply'. Path: \(components.path)")
                return nil
            }
            baseURL = "purchasely://ply"
            pathComponents = Array(allComponents.dropFirst())
        } else {
            print("Error: URL scheme/host not recognized. Scheme: \(components.scheme ?? "nil"), Host: \(components.host ?? "nil")")
            return nil
        }

        guard pathComponents.count == 2,
              (pathComponents[0] == "presentations" || pathComponents[0] == "flows"
                || pathComponents[0] == "redeem"),
              !pathComponents[1].isEmpty else {
            print("Error: URL path does not match '/presentations/{id}', '/flows/{id}' or '/redeem/{token}' format. Path: \(components.path)")
            return nil
        }
        let presentationId = pathComponents[1]

        let queryItems = components.queryItems
        let apiKey = queryItems?.first(where: { $0.name == "api_key" })?.value

        return ParsedPurchaselyURLInfo(
            baseURL: baseURL,
            deeplinkPath: pathComponents[0],
            presentationId: presentationId,
            apiKey: apiKey,
            auid: queryItems?.first(where: { $0.name == "auid" })?.value
        )
    }
}
