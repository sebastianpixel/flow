import Environment
import Request
import UI

public struct MergePullRequest: Procedure {
    public init() {}

    public func run() -> Bool {
        guard let project = Env.current.git.projectOrUser,
            let repository = Env.current.git.currentRepo,
            let pullRequests = GetPullRequests(
                stashProject: project,
                repository: repository
            )
            .awaitResponseWithDebugPrinting()?
            .values else { return false }

        guard !pullRequests.isEmpty else {
            Env.current.shell.write("No open pull requests!")
            return true
        }

        guard let pullRequest = LineSelector(
            dataSource: GenericLineSelectorDataSource(
                items: pullRequests,
                line: \.description
            )
        )?
            .singleSelection()?
            .output,
            PostMergePullRequest(stashProject: project, repository: repository, pullRequestId: pullRequest.id, pullRequestVersion: pullRequest.version)
            .awaitResponseWithDebugPrinting() != nil else { return false }

        if Env.current.shell.promptDecision("Remove the remote branch?") {
            _ = Env.current.git.deleteRemote(branch: pullRequest.fromRef.displayId)
        }

        if Env.current.shell.promptDecision("Remove the local branch?"),
            Env.current.git.checkout(pullRequest.toRef.displayId) {
            _ = Env.current.git.deleteLocal(branch: pullRequest.fromRef.displayId, forced: true)
        }

        if Env.current.shell.promptDecision("Update the JIRA issue?") {
            return SetTransition().run()
        }

        return true
    }
}
