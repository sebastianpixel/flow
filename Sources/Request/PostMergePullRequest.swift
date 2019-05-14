import Environment
import Foundation
import Model

public struct PostMergePullRequest: Request {
    let stashProject: String
    let repository: String
    let pullRequestId: String

    public init(stashProject: String, repository: String, pullRequestId: String) {
        self.stashProject = stashProject
        self.repository = repository
        self.pullRequestId = pullRequestId
    }

    public typealias Response = Empty

    public let method = HTTPMethod.post
    public let host = Env.current.git.host
    public var path: String { return "/rest/api/1.0/projects/\(stashProject)/repos/\(repository)/pull-requests/\(pullRequestId)/merge" }
    public var httpBody = Data?.none
    public let queryItems = [URLQueryItem]()
}
