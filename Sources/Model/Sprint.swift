public struct Sprint: Codable {
    public let closed: Bool
    public let viewBoardsUrl: String
    public let name: String
    public let id: Int

    public struct Response: Codable {
        public let sprints: [Sprint]
    }
}
