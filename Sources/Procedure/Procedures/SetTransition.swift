import Environment
import Request
import UI

public struct SetTransition: Procedure {
    private let issueKey: String?

    public init(issueKey: String? = Env.current.jira.currentIssueKey()) {
        self.issueKey = issueKey
    }

    public func run() -> Bool {
        guard let issueKey = issueKey,
            let response = GetIssueTransitions(issueKey: issueKey).awaitResponseWithDebugPrinting(),
            let transition = LineSelector(dataSource: GenericLineSelectorDataSource(items: response.transitions, line: \.name))?.singleSelection()?.output,
            PostTransition(issueKey: issueKey, transitionId: transition.id).awaitResponseWithDebugPrinting() != nil
        else { return false }
        return true
    }
}
