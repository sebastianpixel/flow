import Environment
import Foundation
import Model

public struct GetIssues: Request {
    let jiraProject: String
    let types: [Issue.IssueType]
    let limit: Int

    public init(jiraProject: String, types: [Issue.IssueType.Name], limit: Int) {
        self.jiraProject = jiraProject
        self.types = types.map { $0.issueType }
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
            .init(name: "jql", value: #"project=\#(jiraProject)+AND+status+in+(Open,"Next","To Do")+AND+issuetype+in+(\#(issueTypes))+order+by+updatedDate"#),
            .init(name: "fields", value: "key,summary,issuetype,parent,updated"),
            .init(name: "maxResults", value: "\(limit)")
        ]
    }
}
