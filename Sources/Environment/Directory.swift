import Foundation

public protocol Directory {
    var path: Path { get }

    init(path: Path, create: Bool) throws

    @discardableResult
    init(path: Path, create: Bool, write: (Directory) throws -> Void) throws

    func contents() throws -> [URL]
    func file(_ name: String) -> File

    @discardableResult
    func file(_ name: String, write: () -> String) throws -> File

    func remove() throws
}

struct DirectoryImpl: Directory {
    enum Error: Swift.Error {
        case nonDirectoryFileAlreadyExistsAtPath(String)
    }

    let path: Path

    func contents() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: path.url, includingPropertiesForKeys: nil, options: [])
    }

    init(path: Path, create: Bool) throws {
        try self.init(path: path, create: create, write: { _ in })
    }

    @discardableResult
    init(path: Path, create: Bool, write: (Directory) throws -> Void) throws {
        self.path = path

        if create {
            var isDirectory = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: path.url.absoluteString, isDirectory: &isDirectory)

            if exists, !isDirectory.boolValue {
                throw Error.nonDirectoryFileAlreadyExistsAtPath(path.url.absoluteString)
            } else if !exists {
                try FileManager.default.createDirectory(at: path.url, withIntermediateDirectories: false, attributes: nil)
            }
        }

        try write(self)
    }

    func file(_ name: String) -> File {
        Env.current.file.init(path: path.appending(name))
    }

    @discardableResult
    func file(_ name: String, write: @autoclosure () -> String) throws -> File {
        try Env.current.file.init(path: path.appending(name), write: write)
    }

    func remove() throws {
        try FileManager.default.removeItem(at: path.url)
    }
}
