import Fixture
import Model
import Utils
import XCTest

class SprintTests: XCTestCase {
    func testMapping() {
        let response = Sprint.Response.mock

        XCTAssertEqual(response.sprints.count, 1)

        let sprint = response.sprints.first!

        XCTAssertFalse(sprint.closed)
        XCTAssertEqual(sprint.viewBoardsUrl, "https://jira.company.com/secure/GHGoToBoard.jspa?sprintId=1234")
    }
}
