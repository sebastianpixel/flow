import Environment
import Foundation
import Model

public struct PostMoveIssuesToSprint: Request {
    private let sprint: Sprint
    private let issues: [Issue]

    public init(sprint: Sprint, issues: [Issue]) {
        self.sprint = sprint
        self.issues = issues
    }

    public typealias Response = Empty

    public let method = HTTPMethod.post
    public let host = Env.current.jira.host
    public var path: String { return "/rest/agile/1.0/sprint/\(sprint.id)/issue" }
    public var httpBody: Data? {
        do {
            return try ["issues": issues.map { $0.key }].encoded()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public let queryItems = [URLQueryItem]()
}
