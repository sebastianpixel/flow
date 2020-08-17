import Environment
import Request
import UI

public struct MergeOrRebase: Procedure {

    public enum Mode {
        case merge, rebase
    }

    private let branch: String?
    private let expression: String?
    private let all: Bool
    private let parent: Bool
    private let mode: Mode

    public init(branch: String?, all: Bool, parent: Bool, expression: String?, mode: Mode) {
        self.branch = branch
        self.all = all
        self.parent = parent
        self.expression = expression
        self.mode = mode
    }

    public func run() -> Bool {
        guard let currentBranch = Env.current.git.currentBranch else {
            Env.current.shell.write("No current branch.")
            return false
        }
        let branchToMerge: String
        if let branch = branch, !branch.isEmpty {
            branchToMerge = branch
        } else if let pattern = expression,
            let branch = Env.current.git.branch(containing: pattern, excludeCurrent: true, options: .regularExpression)
        {
            branchToMerge = branch
        } else if parent,
            let currentIssueKey = Env.current.jira.currentIssueKey(),
            let parentIssueKey = GetIssue(issueKey: currentIssueKey).awaitResponseWithDebugPrinting()?.fields.parent?.key,
            let parentIssueBranch = Env.current.git.branch(containing: parentIssueKey, excludeCurrent: true)
        {
            branchToMerge = parentIssueBranch
        } else {
            let branches = Env.current.git.branches(all ? .all : .local)
            let dataSource = GenericLineSelectorDataSource(items: branches)
            let lineSelector = LineSelector(dataSource: dataSource)
            guard let selection = lineSelector?.singleSelection()?.output else {
                return true
            }
            branchToMerge = selection
        }

        return Env.current.git.checkout(branchToMerge)
            && Env.current.git.pull()
            && Env.current.git.checkout(currentBranch)
            && (mode == .merge ? Env.current.git.merge : Env.current.git.rebase)(branchToMerge)
    }
}
