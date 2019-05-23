import Foundation

public protocol Directory {
    var path: String { get }

    @discardableResult
    init(path: Path, write: (Directory) throws -> Void) throws

    func file(_ name: String) -> File

    @discardableResult
    func file(_ name: String, write: () -> String) throws -> File

    func remove() throws
}

public struct Path: ExpressibleByStringLiteral {
    public let value: String

    public init(stringLiteral value: String) {
        self.value = value.appendingIfNeeded(suffix: "/")
    }

    public static let current = Path(stringLiteral: FileManager.default.currentDirectoryPath)
    public static var temp: Path {
        let randomName = ProcessInfo.processInfo.globallyUniqueString
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(randomName, isDirectory: true).path
        return Path(stringLiteral: path)
    }
}

struct DirectoryImpl: Directory {
    enum Error: Swift.Error {
        case nonDirectoryFileAlreadyExistsAtPath(String)
    }

    let path: String

    @discardableResult
    init(path: Path, write: (Directory) throws -> Void) throws {
        self.path = path.value

        var isDirectory = ObjCBool(false)
        let exists = FileManager.default.fileExists(atPath: self.path, isDirectory: &isDirectory)

        if exists, !isDirectory.boolValue {
            throw Error.nonDirectoryFileAlreadyExistsAtPath(path.value)
        } else if !exists {
            try FileManager.default.createDirectory(atPath: self.path, withIntermediateDirectories: false, attributes: nil)
        }

        try write(self)
    }

    func file(_ name: String) -> File {
        return Env.current.file.init(path: path.appending(name))
    }

    @discardableResult
    func file(_ name: String, write: @autoclosure () -> String) throws -> File {
        return try Env.current.file.init(path: path.appending(name), write: write)
    }

    func remove() throws {
        try FileManager.default.removeItem(atPath: path)
    }
}
