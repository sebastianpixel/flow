import Fixture
import Model
import Utils
import XCTest

class EpicTests: XCTestCase {
    func testMapping() {
        let response = Epic.mock

        XCTAssertEqual(response.fields.name, "Title of Epic")
        XCTAssertEqual(response.fields.summary, "Summary of Epic")
    }
}
