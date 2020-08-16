import Environment
import Request
import UI

public struct CheckoutBranch: Procedure {
    private let all: Bool
    private let parent: Bool
    private let pattern: String?

    public init(all: Bool, parent: Bool, pattern: String?) {
        self.all = all
        self.parent = parent
        self.pattern = pattern
    }

    public func run() -> Bool {
        if let pattern = pattern,
            let branch = Env.current.git.branch(containing: pattern, excludeCurrent: true, options: [.regularExpression])
        {
            return Env.current.git.checkout(branch)
        }

        if parent,
            let currentIssueKey = Env.current.jira.currentIssueKey(),
            let parentIssueKey = GetIssue(issueKey: currentIssueKey).awaitResponseWithDebugPrinting()?.fields.parent?.key,
            let parentIssueBranch = Env.current.git.branches(.all).first(where: { $0.contains(parentIssueKey) })
        {
            return Env.current.git.checkout(parentIssueBranch)
        }

        let branches = Env.current.git.branches(all ? .all : .local)
        if branches.isEmpty, let current = Env.current.git.currentBranch {
            Env.current.shell.write("\(current) is the only branch.")
            return false
        }

        let dataSource = GenericLineSelectorDataSource(items: branches)
        return LineSelector(dataSource: dataSource)?
            .singleSelection()
            .flatMap(\.output)
            .map(Env.current.git.checkout) ?? true
    }
}
