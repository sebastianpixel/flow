import Fixture
import Model
import Utils
import XCTest

class IssueTests: XCTestCase {
    func testMapping() {
        let response = Issue.mock

        let issue = response

        XCTAssertEqual(issue.id, 5678)
        XCTAssertEqual(issue.fields.parent?.id, 5677)

        XCTAssertEqual(issue.key, "PROJECT-1001")
        XCTAssertEqual(issue.fields.parent?.key, "PROJECT-1000")

        XCTAssertEqual(issue.fields.issuetype.name, Issue.IssueType.Name.subTask.rawValue)
        XCTAssertEqual(issue.fields.parent?.fields.issuetype.name, Issue.IssueType.Name.story.rawValue)

        XCTAssertEqual(issue.fields.summary, "Child title goes here")
        XCTAssertEqual(issue.fields.parent?.fields.summary, "Parent title goes here")

        XCTAssertEqual(issue.fields.updated?.timeIntervalSince1970, 1_554_814_788.0)
        XCTAssertNil(issue.fields.parent?.fields.updated)

        XCTAssertEqual(issue.branchName, "feature-PROJECT-1001-child-title-goes-here")
        XCTAssertEqual(issue.fields.parent?.branchName, "feature-PROJECT-1000-parent-title-goes-here")

        XCTAssertEqual(issue.fields.parent?.fields.description, "Description goes here")
        XCTAssertEqual(issue.fields.parent?.fields.fixVersions.count, 1)
        XCTAssertEqual(issue.fields.parent?.fields.fixVersions.first?.name, "macOS")
        XCTAssertEqual(issue.fields.parent?.fields.epicLink, "PROJECT-56")
    }
}
