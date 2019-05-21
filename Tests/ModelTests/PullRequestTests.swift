import Fixture
import Model
import Utils
import XCTest

class PullRequestTests: XCTestCase {
    func testMapping() {
        let response = PullRequest.Response.mock

        XCTAssertEqual(response.values.count, 1)

        let pullRequest = response.values.first!

        XCTAssertEqual(pullRequest.id, 1060)
        XCTAssertEqual(pullRequest.state, "OPEN")
        XCTAssertEqual(pullRequest.title, "feature-PROJECT-1234-branch-name")
        XCTAssertEqual(pullRequest.fromRef.displayId, "feature-PROJECT-1234-branch-name")
        XCTAssertEqual(pullRequest.toRef.displayId, "develop")
        XCTAssertEqual(pullRequest.links.linksSelf.count, 1)
        XCTAssertEqual(pullRequest.links.linksSelf.first?.href, "https://stash.company.com/projects/PROJECT/repos/repo-name/pull-requests/1060")

        XCTAssertEqual(pullRequest.reviewers.count, 1)
        XCTAssertEqual(pullRequest.reviewers.first?.approved, false)
        XCTAssertEqual(pullRequest.reviewers.first?.user.displayName, "Billy Joel")

        XCTAssertTrue(pullRequest.open)
        XCTAssertFalse(pullRequest.closed)
        XCTAssertFalse(pullRequest.locked)

        XCTAssertNil(pullRequest.descriptionText)
        XCTAssertEqual(pullRequest.description, "feature-PROJECT-1234-branch-name; Billy Joel 😶")
    }
}
