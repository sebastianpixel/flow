import Environment
import Foundation
import Model

public struct PostTransition: Request {
    let issueKey: String
    let transitionId: String

    public init(issueKey: String, transitionId: String) {
        self.issueKey = issueKey
        self.transitionId = transitionId
    }

    public typealias Response = Empty

    public let method = HTTPMethod.post
    public let host = Env.current.jira.host
    public var path: String { "/rest/api/2/issue/\(issueKey)/transitions" }
    public var httpBody: Data? {
        let body = [
            "transition": [
                "id": transitionId
            ],
            "fields": [String: String]()
        ]
        do {
            return try body.encoded()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public let queryItems = [URLQueryItem]()
}
