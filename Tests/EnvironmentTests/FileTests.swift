import Environment
import XCTest

class FileTests: XCTestCase {
    func testExistsPositive() {
        let path = Path(stringLiteral: FileManager.default.currentDirectoryPath)
        XCTAssertTrue(Env.current.file.init(path: path).exists)
    }

    func testExistsNegative() {
        XCTAssertFalse(Env.current.file.init().exists)
    }

    func testWrite() throws {
        let file = Env.current.file.init()
        XCTAssertNoThrow(try file.write("Hello world!"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path.url.path))
        let content = FileManager.default.contents(atPath: file.path.url.path).flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(content, "Hello world!")
        try file.remove()
    }

    func testRead() throws {
        let file = try Env.current.file.init { name }
        XCTAssertEqual(try file.read(), name)
        try file.remove()
    }

    func testRemove() throws {
        let file = Env.current.file.init()
        try file.write("")
        XCTAssertTrue(file.exists)
        XCTAssertNoThrow(try file.remove())
        XCTAssertFalse(file.exists)
    }
}
