import Fixture
import Model
import Utils
import XCTest

class ProjectsTest: XCTestCase {
    func testMapping() {
        let response = Project.Response.mock

        XCTAssertEqual(response.count, 1)

        let responseElement = response.first!

        XCTAssertEqual(responseElement.id, "123")
        XCTAssertEqual(responseElement.key, "PROJECT")
        XCTAssertEqual(responseElement.name, "Custom name goes here")
    }
}
