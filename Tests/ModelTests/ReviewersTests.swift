import Fixture
import Model
import Utils
import XCTest

class ReviewersTests: XCTestCase {
    func testMapping() {
        let response = Reviewer.Response.mock

        XCTAssertEqual(response.count, 1)

        let responseElement = response.first!

        XCTAssertEqual(responseElement.id, 14)
        XCTAssertEqual(responseElement.requiredApprovals, 0)

        XCTAssertEqual(responseElement.reviewers.count, 1)

        let reviewer = responseElement.reviewers.first!

        XCTAssertTrue(reviewer.active!)
        XCTAssertEqual(reviewer.displayName, "Tom Jones")
        XCTAssertEqual(reviewer.name, "tjones")
    }
}
