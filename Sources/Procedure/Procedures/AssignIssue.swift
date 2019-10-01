import Environment
import Model
import Request
import UI

import Foundation

public struct AssignIssue: Procedure {
    let issueKey: String?
    let assignToSelf: Bool
    let unassign: Bool

    enum Error: Swift.Error {
        case noAssignee
    }

    public init(issueKey: String?, assignToSelf: Bool, unassign: Bool) {
        self.issueKey = issueKey
        self.assignToSelf = assignToSelf
        self.unassign = unassign
    }

    public func run() -> Bool {
        guard let issueKey = getIssueKey(from: issueKey),
            let stashProject = Env.current.git.projectOrUser,
            let repo = Env.current.git.currentRepo else { return false }

        let result: Result<PutIssueAssignee.Response, Swift.Error>
        if unassign {
            result = PutIssueAssignee(issueKey: issueKey, username: "").request().await()
        } else if assignToSelf {
            let username = Env.current.login.username
            result = PutIssueAssignee(issueKey: issueKey, username: username).request().await()
        } else {
            let committers = getCommitters(stashProject: stashProject, repo: repo).await()
            let assignee = committers.flatMap { committers -> Result<User, Swift.Error> in
                guard
                    !committers.isEmpty,
                    let selector = LineSelector(dataSource: GenericLineSelectorDataSource(items: committers, line: \User.description)),
                    let assignee = selector.singleSelection()?.output else { return .failure(Error.noAssignee) }
                return .success(assignee)
            }
            result = assignee.flatMap { PutIssueAssignee(issueKey: issueKey, username: $0.name).request().await() }
        }

        switch result {
        case .success: return true
        case let .failure(failure):
            if Env.current.debug {
                Env.current.shell.write("\(failure)")
            }
            switch failure {
            case let ApiClientError.status(_, bitbucketError?):
                Env.current.shell.write(bitbucketError.message)
                return false
            case Error.noAssignee:
                return true
            default:
                return false
            }
        }
    }
}
