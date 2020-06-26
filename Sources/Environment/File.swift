import Foundation

public protocol File {
    var path: Path { get }
    var exists: Bool { get }

    init()
    init(path: Path)

    @discardableResult
    init(write: () -> String) throws

    @discardableResult
    init(path: Path, write: () -> String) throws

    func read() throws -> String
    func write(_ text: String) throws
    func remove() throws
}

struct FileImpl: File {
    let path: Path

    init() {
        self.init(path: .temp(isDirectory: false))
    }

    init(path: Path) {
        self.path = path
    }

    @discardableResult
    init(write: () -> String) throws {
        try self.init(path: .temp(isDirectory: false), write: write)
    }

    @discardableResult
    init(path: Path, write: () -> String) throws {
        self.init(path: path)
        try self.write(write())
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: path.url.path)
    }

    func read() throws -> String {
        try String(contentsOf: path.url, encoding: .utf8)
    }

    func write(_ text: String) throws {
        try text.write(to: path.url, atomically: true, encoding: .utf8)
    }

    func remove() throws {
        try FileManager.default.removeItem(at: path.url)
    }
}
