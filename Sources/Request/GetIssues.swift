import Environment
import Foundation
import Model

public struct GetIssues: Request {
    let jiraProject: String
    let types: [Issue.IssueType.Name]
    let limit: Int

    public init(jiraProject: String, types: [Issue.IssueType.Name], limit: Int) {
        self.jiraProject = jiraProject
        self.types = types
        self.limit = limit
    }

    public typealias Response = Issue.Response

    public let method = HTTPMethod.get
    public let host = Env.current.jira.host
    public let path = "/rest/api/2/search"
    public let httpBody = Data?.none
    public var queryItems: [URLQueryItem] {
        let issueTypes = types.map(\.jqlSearchTerm).joined(separator: ",")
        return [
            .init(name: "jql", value: #"project=\#(jiraProject)+AND+issuetype+in+(\#(issueTypes))+order+by+updatedDate"#),
            .init(name: "fields", value: "key,summary,issuetype,parent,updated,customfield_10223"),
            .init(name: "maxResults", value: "\(limit)")
        ]
    }
}
