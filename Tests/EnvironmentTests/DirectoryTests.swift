import Environment
import XCTest

class DirectoryTests: XCTestCase {
    func testTempPath() {
        let path = Path.temp(isDirectory: true)
        XCTAssertTrue(path.url.path.hasPrefix(FileManager.default.temporaryDirectory.path))

        XCTAssertFalse(FileManager.default.fileExists(atPath: path.url.path))
    }

    func testCreateDirectoryInInit() throws {
        let dir = try Env.current.directory.init(path: .temp(isDirectory: true), write: { _ in })

        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path.url.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)

        try dir.remove()
    }

    func testCreateFileWhenInitializingDirectory() throws {
        var file: File!

        let dir = try Env.current.directory.init(path: .temp(isDirectory: true)) {
            file = try $0.file("test") {
                "Test"
            }
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path.url.path))

        try dir.remove()
    }

    func testRemove() throws {
        let dir = try Env.current.directory.init(path: .temp(isDirectory: true), write: { _ in })
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path.url.path))
        try dir.remove()
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.path.url.path))
    }
}
