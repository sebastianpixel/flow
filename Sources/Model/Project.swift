public struct Project: Codable, CustomStringConvertible, Equatable {
    public let id: String
    public let key: String
    public let name: String

    public typealias Response = [Project]

    public var description: String {
        "\(key) \"\(name)\""
    }
}
