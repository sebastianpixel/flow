import Environment
import Foundation
import Model

public struct GetIssue: Request {
    let issueKey: String

    public init(issueKey: String) {
        self.issueKey = issueKey
    }

    public typealias Response = Issue

    public let method = HTTPMethod.get
    public var path: String {
        "/rest/api/2/issue/\(issueKey)"
    }

    public let host = Env.current.jira.host
    public let queryItems = [URLQueryItem]()
    public let httpBody = Data?.none
}
