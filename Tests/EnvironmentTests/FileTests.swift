import Environment
import XCTest

class FileTests: XCTestCase {
    func testTempPath() {
        let path = Env.current.file.tempPath()
        XCTAssertTrue(path.hasPrefix(FileManager.default.temporaryDirectory.path))

        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    func testExistsPositive() {
        let path = FileManager.default.currentDirectoryPath
        XCTAssertTrue(Env.current.file.init(path: path).exists)
    }

    func testExistsNegative() {
        XCTAssertFalse(Env.current.file.init().exists)
    }

    func testWrite() throws {
        let file = Env.current.file.init()
        XCTAssertNoThrow(try file.write("Hello world!"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        let content = FileManager.default.contents(atPath: file.path).flatMap { String(data: $0, encoding: .utf8) }
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
