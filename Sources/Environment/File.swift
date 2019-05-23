import Foundation

public protocol File {
    var path: String { get }
    var url: URL { get }
    var exists: Bool { get }

    static func tempPath() -> String

    init()
    init(path: String)

    @discardableResult
    init(write: () -> String) throws

    @discardableResult
    init(path: String, write: () -> String) throws

    func read() throws -> String
    func write(_ text: String) throws
    func remove() throws
}

struct FileImpl: File {
    let path: String
    let url: URL

    init() {
        self.init(path: FileImpl.tempPath())
    }

    init(path: String) {
        self.path = path
        url = URL(fileURLWithPath: path)
    }

    @discardableResult
    init(write: () -> String) throws {
        try self.init(path: FileImpl.tempPath(), write: write)
    }

    @discardableResult
    init(path: String, write: () -> String) throws {
        self.init(path: path)
        try self.write(write())
    }

    static func tempPath() -> String {
        let randomName = ProcessInfo.processInfo.globallyUniqueString
        return FileManager.default.temporaryDirectory.appendingPathComponent(randomName, isDirectory: false).path
    }

    var exists: Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    func read() throws -> String {
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    func write(_ text: String) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    func remove() throws {
        try FileManager.default.removeItem(at: url)
    }
}
