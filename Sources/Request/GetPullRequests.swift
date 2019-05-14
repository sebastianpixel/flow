import Environment
import Foundation
import Model

public struct GetPullRequests: Request {
    let stashProject: String
    let repository: String

    public init(stashProject: String, repository: String) {
        self.stashProject = stashProject
        self.repository = repository
    }

    public typealias Response = PullRequest.Response

    public let method = HTTPMethod.get
    public var path: String {
        return "/rest/api/1.0/projects/\(stashProject)/repos/\(repository)/pull-requests"
    }

    public let host = Env.current.git.host
    public let httpBody = Data?.none
    public let queryItems = [URLQueryItem(name: "state", value: "OPEN")]
}
