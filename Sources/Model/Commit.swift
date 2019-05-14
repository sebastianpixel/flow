public struct Commit: Codable {
    public let committer: User

    public struct Response: Codable {
        public let values: [Commit]
    }
}
