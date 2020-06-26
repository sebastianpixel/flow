import Environment
import Foundation
import Model

public struct GetLastCommits: Request {
    let stashProject: String
    let repo: String
    let limit: Int

    public init(stashProject: String, repo: String, limit: Int) {
        self.stashProject = stashProject
        self.repo = repo
        self.limit = limit
    }

    public typealias Response = Commit.Response

    public let method = HTTPMethod.get
    public let host = Env.current.git.host
    public var path: String { "/rest/api/1.0/projects/\(stashProject)/repos/\(repo)/commits" }
    public let httpBody = Data?.none
    public var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
    }
}
