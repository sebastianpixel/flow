import Environment
import Foundation
import Model

public struct GetEpic: Request {
    let issueKey: String

    public init(issueKey: String) {
        self.issueKey = issueKey
    }

    public typealias Response = Epic

    public let method = HTTPMethod.get
    public let host = Env.current.jira.host
    public var path: String {
        return "/rest/api/2/issue/\(issueKey)"
    }

    public let httpBody = Data?.none
    public let queryItems = [URLQueryItem(name: "fields", value: "summary,customfield_10523")]
}
