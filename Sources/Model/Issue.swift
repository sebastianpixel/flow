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
        let components = [fields.issuetype.displayName, key] + fieldsStripped
        return components.filter { !$0.isEmpty }.joined(separator: "-")
    }
}

extension Issue: Equatable {
    public static func == (lhs: Issue, rhs: Issue) -> Bool {
        lhs.id == rhs.id
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
        public let description: String?
        public let fixVersions: [FixVersion]
        public let epicLink: String?
        public let storyPoints: Double?

        enum CodingKeys: String, CodingKey {
            case summary, parent, issuetype, updated, description, fixVersions, customfield_10522, customfield_10223
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            summary = try container.decode(String.self, forKey: .summary)
            issuetype = try container.decode(IssueType.self, forKey: .issuetype)
            fixVersions = try container.decodeIfPresent([FixVersion].self, forKey: .fixVersions) ?? []
            parent = try container.decodeIfPresent(Issue.self, forKey: .parent)
            updated = try container.decodeIfPresent(Date.self, forKey: .updated)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            epicLink = try container.decodeIfPresent(String.self, forKey: .customfield_10522)
            storyPoints = try container.decodeIfPresent(Double.self, forKey: .customfield_10223)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(summary, forKey: .summary)
            try container.encode(parent, forKey: .parent)
            try container.encode(issuetype, forKey: .issuetype)
            try container.encode(updated, forKey: .updated)
            try container.encode(description, forKey: .description)
            try container.encode(fixVersions, forKey: .fixVersions)
            try container.encode(epicLink, forKey: .customfield_10522)
            try container.encode(storyPoints, forKey: .customfield_10223)
        }
    }

    struct FixVersion: Codable, Equatable {
        public let name: String
    }

    struct IssueType: Codable, Equatable {
        public let name: String

        public var displayName: String {
            name.lowercased().contains("bug") ? "bugfix" : "feature"
        }

        public enum Name: String {
            case
                story = "Story",
                bug = "Bug",
                epic = "Epic",
                subTask = "Sub-task",
                techStory = "Technische Story",
                bugSub = "Bug (sub)",
                unplanned = "Unplanned"

            public var jqlSearchTerm: String {
                #""\#(rawValue.replacingOccurrences(of: " ", with: "+"))""#
            }

            public var issueType: IssueType {
                IssueType(name: rawValue)
            }
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
