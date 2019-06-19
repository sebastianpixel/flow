import Foundation

public struct Path: ExpressibleByStringLiteral {
    public var url: URL

    public init(stringLiteral value: String) {
        url = URL(fileURLWithPath: value)
    }

    public init(url: URL) {
        self.url = url
    }

    public func appending(_ component: String) -> Path {
        return Path(url: url.appendingPathComponent(component))
    }

    public func extending(with extension: String) -> Path {
        return Path(stringLiteral: url.path.removingIfNeeded(suffix: "/").appending(`extension`))
    }

    public static let current = Path(stringLiteral: FileManager.default.currentDirectoryPath)
    public static func temp(isDirectory: Bool) -> Path {
        let randomName = ProcessInfo.processInfo.globallyUniqueString
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(randomName, isDirectory: isDirectory).path
        return Path(stringLiteral: isDirectory ? path.appendingIfNeeded(suffix: "/") : path)
    }
}

extension String.StringInterpolation {
    public mutating func appendInterpolation(_ value: Path) {
        appendLiteral(value.url.path)
    }
}
