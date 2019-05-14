public struct Reviewer: Codable {
    public let id: Int
    public let requiredApprovals: Int
    public let reviewers: [User]

    public typealias Response = [Reviewer]
}
