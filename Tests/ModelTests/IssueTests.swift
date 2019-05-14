import Fixture
import Model
import Utils
import XCTest

class IssueTests: XCTestCase {
    func testMapping() {
        let response = Issue.Response.mock

        XCTAssertEqual(response.issues.count, 2)

        let issue = response.issues.last!

        XCTAssertEqual(issue.id, 5678)
        XCTAssertEqual(issue.fields.parent?.id, 5677)

        XCTAssertEqual(issue.key, "PROJECT-1001")
        XCTAssertEqual(issue.fields.parent?.key, "PROJECT-1000")

        XCTAssertEqual(issue.fields.issuetype.name, .subTask)
        XCTAssertEqual(issue.fields.parent?.fields.issuetype.name, .story)

        XCTAssertEqual(issue.fields.summary, "Child title goes here")
        XCTAssertEqual(issue.fields.parent?.fields.summary, "Parent title goes here")

        XCTAssertEqual(issue.fields.updated?.timeIntervalSince1970, 1_554_814_788.0)
        XCTAssertNil(issue.fields.parent?.fields.updated)

        XCTAssertEqual(issue.branchName, "feature-PROJECT-1001-child-title-goes-here")
        XCTAssertEqual(issue.fields.parent?.branchName, "feature-PROJECT-1000-parent-title-goes-here")
    }
}
