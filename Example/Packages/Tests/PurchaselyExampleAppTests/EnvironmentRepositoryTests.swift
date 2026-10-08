import XCTest
@testable import PurchaselyExampleApp

final class EnvironmentRepositoryTests: XCTestCase {

    private let key = "ALLOW_CAMPAIGNS_ENABLED"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    func testAllowCampaignsDefaultsToTrueWhenKeyIsAbsent() {
        UserDefaults.standard.removeObject(forKey: key)
        XCTAssertTrue(EnvironmentRepository.shared.isAllowCampaignsEnabled())
    }

    func testAllowCampaignsKeepsAStoredFalse() {
        EnvironmentRepository.shared.setAllowCampaignsEnabled(false)
        XCTAssertFalse(EnvironmentRepository.shared.isAllowCampaignsEnabled())
    }
}
