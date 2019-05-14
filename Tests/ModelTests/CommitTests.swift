import Fixture
import Model
import Utils
import XCTest

class CommitTest: XCTestCase {
    func testMapping() {
        let response = Commit.Response.mock

        XCTAssertEqual(response.values.count, 1)

        let committer = response.values.first!.committer

        XCTAssertTrue(committer.active)
        XCTAssertEqual(committer.displayName, "Tom Jones")
        XCTAssertEqual(committer.name, "tjones")

        XCTAssertEqual(committer.description, "Tom Jones (\"tjones\")")
    }
}
