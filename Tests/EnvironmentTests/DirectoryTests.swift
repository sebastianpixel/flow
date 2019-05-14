import Environment
import XCTest

class DirectoryTests: XCTestCase {
    func testTempPath() {
        let path = Env.current.directory.tempPath()
        XCTAssertTrue(path.hasPrefix(FileManager.default.temporaryDirectory.path))

        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    func testCreateDirectoryInInit() throws {
        let dir = try Env.current.directory.init(write: { _ in })

        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)

        try dir.remove()
    }

    func testCreateFileWhenInitializingDirectory() throws {
        var file: File!

        let dir = try Env.current.directory.init {
            file = try $0.file("test") {
                "Test"
            }
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))

        try dir.remove()
    }

    func testRemove() throws {
        let dir = try Env.current.directory.init(write: { _ in })
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path))
        try dir.remove()
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.path))
    }
}
