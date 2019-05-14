import Environment
import Model
import Request
import UI

import Foundation

public struct AssignIssue: Procedure {
    let issueKey: String?
    let assignToSelf: Bool

    enum Error: Swift.Error {
        case noAssignee
    }

    public init(issueKey: String?, assignToSelf: Bool) {
        self.issueKey = issueKey
        self.assignToSelf = assignToSelf
    }

    public func run() -> Bool {
        guard let issueKey = getIssueKey(from: issueKey),
            let stashProject = Env.current.git.projectOrUser,
            let repo = Env.current.git.currentRepo else { return false }

        let result: Result<PutIssueAssignee.Response, Swift.Error>
        if assignToSelf {
            let username = Env.current.login.username
            result = PutIssueAssignee(issueKey: issueKey, username: username).request().await()
        } else {
            result = GetLastCommits(stashProject: stashProject, repo: repo, limit: 500)
                .request()
                .await()
                .flatMap { response -> Result<User, Swift.Error> in
                    let committers = response.values.map { $0.committer }
                    guard !committers.isEmpty,
                        let selector = LineSelector(dataSource: GenericLineSelectorDataSource(items: committers, line: \User.description)),
                        let assignee = selector.singleSelection()?.output else { return .failure(Error.noAssignee) }
                    return .success(assignee)
                }
                .flatMap { PutIssueAssignee(issueKey: issueKey, username: $0.name).request().await() }
        }

        switch result {
        case .success: return true
        case let .failure(failure):
            if Env.current.debug {
                Env.current.shell.write("\(failure)")
            }
            if case Error.noAssignee = failure {
                return true
            }
            return false
        }
    }
}
