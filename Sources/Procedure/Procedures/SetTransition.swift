import Environment
import Request
import UI

public struct SetTransition: Procedure {
    public init() {}

    public func run() -> Bool {
        guard let issueKey = Env.current.jira.currentIssueKey(),
            let response = GetIssueTransitions(issueKey: issueKey).awaitResponseWithDebugPrinting(),
            let transition = LineSelector(dataSource: GenericLineSelectorDataSource(items: response.transitions, line: \.name))?.singleSelection()?.output,
            PostTransition(issueKey: issueKey, transitionId: transition.id).awaitResponseWithDebugPrinting() != nil
        else { return false }
        return true
    }
}
