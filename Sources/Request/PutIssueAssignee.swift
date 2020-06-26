import Environment
import Foundation
import Model

public struct PutIssueAssignee: Request {
    let issueKey: String
    let username: String

    public init(issueKey: String, username: String) {
        self.issueKey = issueKey
        self.username = username
    }

    public typealias Response = Empty

    public let method = HTTPMethod.put
    public let host = Env.current.jira.host
    public var path: String { "/rest/api/2/issue/\(issueKey)" }
    public var httpBody: Data? {
        let body = [
            "fields": [
                "assignee": [
                    "name": username
                ]
            ]
        ]
        do {
            return try body.encoded()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public let queryItems = [URLQueryItem]()
}
