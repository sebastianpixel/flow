import Foundation

public protocol Directory {
    var path: String { get }

    static func tempPath() -> String

    @discardableResult
    init(path: String, write: (Directory) throws -> Void) throws

    @discardableResult
    init(write: (Directory) throws -> Void) throws

    @discardableResult
    func file(_ name: String, write: () -> String) throws -> File

    func remove() throws
}

struct DirectoryImpl: Directory {
    let path: String

    @discardableResult
    init(write: (Directory) throws -> Void) throws {
        try self.init(path: DirectoryImpl.tempPath(), write: write)
    }

    @discardableResult
    init(path: String, write: (Directory) throws -> Void) throws {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        self.path = path
        try write(self)
    }

    @discardableResult
    func file(_ name: String, write: () -> String) throws -> File {
        return try Env.current.file.init(path: path.appending(name), write: write)
    }

    func remove() throws {
        try FileManager.default.removeItem(atPath: path)
    }

    static func tempPath() -> String {
        let randomName = ProcessInfo.processInfo.globallyUniqueString
        return FileManager.default.temporaryDirectory.appendingPathComponent(randomName, isDirectory: true).path.appendingIfNeeded(suffix: "/")
    }
}
