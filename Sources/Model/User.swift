public struct User: Codable, CustomStringConvertible, Hashable {
    public let name: String
    public let displayName: String
    public let active: Bool

    public var description: String {
        return "\(displayName) (\"\(name)\")"
    }
}
