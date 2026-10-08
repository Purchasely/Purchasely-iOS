import XCTest
@testable import PurchaselyExampleApp

final class PurchaselyDeeplinkParserTests: XCTestCase {

    func testDropsStagingEnvAndCustomURLs() throws {
        let link = "purchasely://ply/presentations/p1?env=staging&api_url=a.example&tracking_url=t.example&paywall_url=w.example&preview=true"

        let info = try XCTUnwrap(PurchaselyDeeplinkParser.parse(link))
        // The parsed value must not carry any host or environment override.
        let fields = Set(Mirror(reflecting: info).children.compactMap(\.label))
        for forbidden in ["environment", "apiUrl", "trackingUrl", "paywallUrl"] {
            XCTAssertFalse(fields.contains(forbidden), "\(forbidden) must not be parsed")
        }

        // `api_key` is the only parameter the sample consumes: it is hidden from the SDK, and the
        // functional params stay.
        let forwarded = try XCTUnwrap(PurchaselyDeeplinkParser.urlStrippedOfConfigParams(link + "&api_key=K"))
        let names = (URLComponents(url: forwarded, resolvingAgainstBaseURL: false)?.queryItems ?? []).map(\.name)
        XCTAssertFalse(names.contains("api_key"))
        XCTAssertTrue(names.contains("preview"))
    }

    func testKeepsApiKeyAndPresentationId() throws {
        let info = try XCTUnwrap(PurchaselyDeeplinkParser.parse("purchasely://ply/presentations/promo?api_key=KEY123"))
        XCTAssertEqual(info.apiKey, "KEY123")
        XCTAssertEqual(info.presentationId, "promo")
        XCTAssertEqual(info.deeplinkPath, "presentations")
    }

    func testIgnoresUnknownHost() {
        XCTAssertNil(PurchaselyDeeplinkParser.parse("https://evil.example/ply/presentations/p1?api_key=K"))
        XCTAssertNil(PurchaselyDeeplinkParser.parse("purchasely://other/presentations/p1"))
    }
}
