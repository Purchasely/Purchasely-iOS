//
//  DeeplinksViewModel.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 29/04/2024.
//

import Foundation

class DeeplinksViewModel: ObservableObject {

    private let mainViewModel: MainViewModel

    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
    }

    func openDeeplink(with url: String) {
        // Route through MainViewModel so an `api_key` query parameter restarts the SDK
        // with that key, exactly like an external deeplink (onOpenURL / universal link / QR scan).
        mainViewModel.openDeeplink(url: url)
    }

    /// Builds the `{scheme}://ply/redeem/{token}?auid={auid}` deeplink from a redemption token and
    /// routes it like any external deeplink.
    /// The `auid` is optional — omit it to exercise the no-adoption path.
    func redeem(token: String, auid: String) {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else { return }

        var url = "purchasely://ply/redeem/\(trimmedToken)"
        let trimmedAuid = auid.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAuid.isEmpty {
            url += "?auid=\(trimmedAuid)"
        }
        mainViewModel.openDeeplink(url: url)
    }
}
