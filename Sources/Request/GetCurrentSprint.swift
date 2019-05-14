import Environment
import Foundation
import Model

public struct GetCurrentSprint: Request {
    let jiraProject: String

    public init(jiraProject: String) {
        self.jiraProject = jiraProject
    }

    public typealias Response = Sprint.Response

    public let method = HTTPMethod.get
    public let host = Env.current.jira.host
    public let path = "/rest/greenhopper/1.0/integration/teamcalendars/sprint/list"
    public let httpBody = Data?.none
    public var queryItems: [URLQueryItem] {
        return [
            .init(name: "jql", value: "project=\(jiraProject)+and+Sprint+not+in+closedSprints()")
        ]
    }
}
