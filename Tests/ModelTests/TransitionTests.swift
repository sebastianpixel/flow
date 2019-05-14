import Fixture
import Model
import Utils
import XCTest

class TransitionTests: XCTestCase {
    func testMapping() {
        let response = Transition.Response.mock

        XCTAssertEqual(response.transitions.count, 8)

        let inProgress = response.transitions[5]

        XCTAssertEqual(inProgress.id, "231")
        XCTAssertEqual(inProgress.name, "In Progress")
    }
}
