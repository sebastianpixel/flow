import Environment
import Foundation
import Model

public struct GetDefaultReviewers: Request {
    let stashProject: String
    let repo: String

    public init(stashProject: String, repo: String) {
        self.stashProject = stashProject
        self.repo = repo
    }

    public typealias Response = Reviewer.Response

    public let method = HTTPMethod.get
    public let host = Env.current.git.host
    public var path: String { return "/rest/default-reviewers/latest/projects/\(stashProject)/repos/\(repo)/conditions" }
    public let httpBody = Data?.none
    public let queryItems = [URLQueryItem]()
}
