import Environment
import Foundation
import Model

public struct PostPullRequest: Request {
    let stashProject: String
    let repository: String

    let title: String
    let source: String
    let destination: String
    let reviewers: [String]
    let description: String?
    let closeSourceBranch: Bool

    public init(stashProject: String, repository: String, title: String, source: String, destination: String, reviewers: [String], description: String?, closeSourceBranch: Bool) {
        self.stashProject = stashProject
        self.repository = repository
        self.title = title
        self.source = source
        self.destination = destination
        self.reviewers = reviewers
        self.description = description
        self.closeSourceBranch = closeSourceBranch
    }

    public typealias Response = Empty

    public let method = HTTPMethod.post
    public var path: String { "/rest/api/1.0/projects/\(stashProject)/repos/\(repository)/pull-requests" }
    public let host = Env.current.git.host
    public let queryItems = [URLQueryItem]()
    public var httpBody: Data? {
        func branch(id: String) -> [String: Any] {
            [
                "id": id,
                "repository": [
                    "slug": repository,
                    "name": NSNull(),
                    "project": [
                        "key": stashProject
                    ]
                ]
            ]
        }
        var body: [String: Any] = [
            "title": title,
            "fromRef": branch(id: source),
            "toRef": branch(id: destination),
            "reviewers": reviewers.map { name in ["user": ["name": name]] },
            "close_source_branch": closeSourceBranch
        ]
        if let description = description {
            body["description"] = description
        }
        do {
            return try JSONSerialization.data(withJSONObject: body)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
