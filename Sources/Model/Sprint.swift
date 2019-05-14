public struct Sprint: Codable {
    public let closed: Bool
    public let viewBoardsUrl: String

    public struct Response: Codable {
        public let sprints: [Sprint]
    }
}
