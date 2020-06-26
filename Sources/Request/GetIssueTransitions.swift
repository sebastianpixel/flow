import Environment
import Foundation
import Model

public struct GetIssueTransitions: Request {
    let issueKey: String

    public init(issueKey: String) {
        self.issueKey = issueKey
    }

    public typealias Response = Transition.Response

    public let method = HTTPMethod.get
    public let host = Env.current.jira.host
    public var path: String { "/rest/api/2/issue/\(issueKey)/transitions" }
    public let httpBody = Data?.none
    public let queryItems = [URLQueryItem]()
}
