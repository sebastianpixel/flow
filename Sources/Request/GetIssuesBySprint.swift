import Environment
import Foundation
import Model

public struct GetIssuesBySprint: Request {
    let sprint: Sprint
    let types: [Issue.IssueType.Name]
    let limit: Int

    public init(sprint: Sprint, types: [Issue.IssueType.Name], limit: Int) {
        self.sprint = sprint
        self.types = types
        self.limit = limit
    }

    public typealias Response = Issue.Response

    public let method = HTTPMethod.get
    public let host = Env.current.jira.host
    public let path = "/rest/api/2/search"
    public let httpBody = Data?.none
    public var queryItems: [URLQueryItem] {
        let issueTypes = types.map { $0.jqlSearchTerm }.joined(separator: ",")
        return [
            .init(name: "jql", value: #"Sprint=\#(sprint.id)+AND+issuetype+in+(\#(issueTypes))"#),
            .init(name: "fields", value: "key,summary,issuetype,parent,updated,description,fixVersions,customfield_10522"),
            .init(name: "maxResults", value: "\(limit)")
        ]
    }
}
