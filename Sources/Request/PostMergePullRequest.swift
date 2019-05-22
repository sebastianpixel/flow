import Environment
import Foundation
import Model

public struct PostMergePullRequest: Request {
    let stashProject: String
    let repository: String
    let pullRequestId: Int
    let pullRequestVersion: Int

    public init(stashProject: String, repository: String, pullRequestId: Int, pullRequestVersion: Int) {
        self.stashProject = stashProject
        self.repository = repository
        self.pullRequestId = pullRequestId
        self.pullRequestVersion = pullRequestVersion
    }

    public typealias Response = Empty

    public let method = HTTPMethod.post
    public let host = Env.current.git.host
    public var path: String { return "/rest/api/1.0/projects/\(stashProject)/repos/\(repository)/pull-requests/\(pullRequestId)/merge" }
    public var httpBody = Data?.none
    public var queryItems: [URLQueryItem] {
        return [URLQueryItem(name: "version", value: "\(pullRequestVersion)")]
    }
}
