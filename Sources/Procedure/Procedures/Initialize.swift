import Environment
import Model
import Request
import UI
import Utils

public struct Initialize: Procedure {
    enum Error: Swift.Error {
        case
            noIssuesReceived,
            noSelection,
            noIssueKey,
            transitionNotFound(String),
            userOptOut
    }

    private let jiraProject: String?
    private let issueKey: String?

    public init(jiraProject: String?, issueKey: String?) {
        self.jiraProject = jiraProject
        self.issueKey = issueKey
    }

    public func run() -> Bool {
        let issueResult: Result<Issue, Swift.Error>
        if let issueFromProvidedKey = issueKey.map(getIssueKey) {
            issueResult = issueFromProvidedKey.map { GetIssue(issueKey: $0).request().await() } ?? .failure(Error.noIssueKey)
        } else if let project = getJiraProject(from: jiraProject) {
            issueResult = selectFromAllIssues(JIRAproject: project)
        } else {
            issueResult = Result<Issue, Swift.Error>.failure(Error.noIssueKey)
        }

        let result = issueResult
            .map { issue -> String in
                if !Env.current.debug,
                    Env.current.git.createBranch(name: issue.branchName) {
                    _ = Env.current.git.pushSetUpstream()
                }
                return issue.key
            }
            .flatMap { issueKey -> Result<String, Swift.Error> in
                guard Env.current.shell.promptDecision(#"Should the JIRA issue be set to "In Progress"?"#) else {
                    return .success(issueKey)
                }
                return GetIssueTransitions(issueKey: issueKey)
                    .request()
                    .await()
                    .flatMap { response -> Result<String, Swift.Error> in
                        guard let id = response.transitions.first(where: { $0.name == "In Progress" })?.id else {
                            return .failure(Error.transitionNotFound("In Progress"))
                        }
                        return .success(id)
                    }
                    .flatMap { id -> Result<String, Swift.Error> in
                        PostTransition(issueKey: issueKey, transitionId: id)
                            .request()
                            .map { $0.map { _ in issueKey } }
                            .await()
                    }
            }
            .flatMap { issueKey -> Result<Empty, Swift.Error> in
                guard Env.current.shell.promptDecision("Do you want the JIRA issue to be assigned to you?") else {
                    return .failure(Error.userOptOut)
                }
                return PutIssueAssignee(issueKey: issueKey, username: Env.current.login.username)
                    .request()
                    .await()
            }

        switch result {
        case .success:
            return true
        case let .failure(failure):
            if Env.current.debug {
                Env.current.shell.write("\(failure)")
            }
            if case Error.userOptOut = failure {
                return true
            }
            return false
        }
    }

    private func selectFromAllIssues(JIRAproject: String) -> Result<Issue, Swift.Error> {
        return GetIssues(jiraProject: JIRAproject, types: [Issue.IssueType.Name.bug, .bugSub, .story, .subTask, .techStory], limit: 300)
            .request()
            .await()
            .flatMap { result in
                guard !result.issues.isEmpty else { return .failure(Error.noIssuesReceived) }
                let dataSource = IssueLineSelectorDataSource(issues: result.issues)
                return LineSelector(dataSource: dataSource)?.singleSelection()?.output.map { .success($0) } ?? .failure(Error.noSelection)
            }
    }
}
