public struct Transition: Codable, Equatable {
    public let id: String
    public let name: String

    public struct Response: Codable {
        public let transitions: [Transition]
    }
}
