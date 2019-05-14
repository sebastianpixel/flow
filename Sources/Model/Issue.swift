import Foundation

public final class Issue {
    public let id: Int
    public let key: String
    public let fields: Fields

    public init(key: String, fields: Fields, id: Int) {
        self.key = key
        self.fields = fields
        self.id = id
    }

    public var branchName: String {
        let nonAlphaNumeric = CharacterSet.alphanumerics.inverted
        let fieldsStripped = fields.summary
            .folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: nil)
            .lowercased()
            .components(separatedBy: nonAlphaNumeric)
        let components = [fields.issuetype.name.displayName, key] + fieldsStripped
        return components.filter { !$0.isEmpty }.joined(separator: "-")
    }
}

extension Issue: Equatable {
    public static func == (lhs: Issue, rhs: Issue) -> Bool {
        return lhs.id == rhs.id
            && lhs.key == rhs.key
            && lhs.fields == rhs.fields
    }
}

public extension Issue {
    struct Response: Codable {
        public let issues: [Issue]
    }

    struct Fields: Codable, Equatable {
        public let summary: String
        public let parent: Issue?
        public let issuetype: IssueType
        public let updated: Date?
    }

    struct IssueType: Codable, Equatable {
        public let name: Name

        public enum Name: String, Codable, Equatable {
            case
                story = "Story",
                bug = "Bug",
                epic = "Epic",
                subTask = "Sub-task",
                techStory = "Technische Story",
                bugSub = "Bug (sub)",
                unplanned = "Unplanned"

            public var displayName: String {
                return Name.bugTypes.contains(self) ? "bugfix" : "feature"
            }

            public var jqlSearchTerm: String {
                switch self {
                case .story, .bug, .subTask, .unplanned, .epic:
                    return rawValue
                case .bugSub:
                    return #""Bug+(sub)""#
                case .techStory:
                    return #""Technische+Story""#
                }
            }

            static let featureTypes = [Name.story, .subTask, .techStory]
            static let bugTypes = [Name.bug, .bugSub]
        }
    }
}

extension Issue: Codable {
    enum CodingKeys: String, CodingKey {
        case key, fields, id
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = try container.decode(String.self, forKey: .key)
        let fields = try container.decode(Fields.self, forKey: .fields)
        let id = try container.decode(String.self, forKey: .id)

        guard let idAsInt = Int(id) else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: [CodingKeys.id], debugDescription: "Could not convert \(id) to Int"))
        }

        self.init(key: key, fields: fields, id: idAsInt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(fields, forKey: .fields)
        try container.encode("\(id)", forKey: .id)
    }
}
