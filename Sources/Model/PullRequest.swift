public struct PullRequest: Codable, CustomStringConvertible, Equatable {
    public let id: Int
    public let fromRef, toRef: Branch
    public let links: Links
    public let title: String
    public let reviewers: [Reviewer]
    public let author: Reviewer
    public let descriptionText: String?
    public let state: String
    public let open: Bool
    public let closed: Bool
    public let locked: Bool

    enum CodingKeys: CodingKey {
        case fromRef, toRef, links, title, reviewers, description, open, closed, locked, state, id, author
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fromRef = try container.decode(Branch.self, forKey: .fromRef)
        toRef = try container.decode(Branch.self, forKey: .toRef)
        links = try container.decode(Links.self, forKey: .links)
        title = try container.decode(String.self, forKey: .title)
        reviewers = try container.decode([Reviewer].self, forKey: .reviewers)
        descriptionText = try? container.decode(String.self, forKey: .description)
        open = try container.decode(Bool.self, forKey: .open)
        closed = try container.decode(Bool.self, forKey: .closed)
        locked = try container.decode(Bool.self, forKey: .locked)
        state = try container.decode(String.self, forKey: .state)
        id = try container.decode(Int.self, forKey: .id)
        author = try container.decode(Reviewer.self, forKey: .author)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fromRef, forKey: .fromRef)
        try container.encode(toRef, forKey: .toRef)
        try container.encode(links, forKey: .links)
        try container.encode(title, forKey: .title)
        try container.encode(reviewers, forKey: .reviewers)
        try container.encode(descriptionText, forKey: .description)
        try container.encode(open, forKey: .open)
        try container.encode(closed, forKey: .closed)
        try container.encode(locked, forKey: .locked)
        try container.encode(state, forKey: .state)
        try container.encode(id, forKey: .id)
        try container.encode(author, forKey: .author)
    }

    public var description: String {
        return "\(title); \(reviewers.map { "\($0.user.displayName) \($0.statusEmoji)" }.joined(separator: ", "))"
    }

    public struct Response: Codable {
        public let values: [PullRequest]
    }

    public struct Reviewer: Codable, Equatable {
        public let approved: Bool
        public let status: String
        public let user: User

        var statusEmoji: String {
            switch status {
            case "APPROVED": return "✅"
            default: return "🛑"
            }
        }
    }

    public struct Branch: Codable, Equatable {
        public let displayId: String
    }

    public struct Links: Codable, Equatable {
        public let linksSelf: [SelfElement]

        enum CodingKeys: String, CodingKey {
            case linksSelf = "self"
        }
    }

    public struct SelfElement: Codable, Equatable {
        public let href: String
    }
}
