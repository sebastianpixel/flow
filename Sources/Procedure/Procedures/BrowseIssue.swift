import Environment
import Foundation
import Model
import Request

public struct BrowseIssue: Procedure {
    private let issueKey: String?
    private let expression: String?
    private let openParent: Bool

    public init(issueKey: String?, expression: String?, openParent: Bool) {
        self.issueKey = issueKey
        self.expression = expression
        self.openParent = openParent
    }

    public func run() -> Bool {
        let keyOfIssueToOpen: String?

        if let expression = expression,
            let project = Env.current.jira.currentProject {
            let issueTypes: [Issue.IssueType.Name] = [.bug, .bugSub, .story, .subTask, .techStory]
            let issues = GetIssues(jiraProject: project, types: issueTypes, limit: 300).request().await()
            switch issues {
            case let .success(success):
                keyOfIssueToOpen = success.issues.first {
                    $0.key == expression
                        || $0.key.extracting(.numbersPattern) == expression
                        || $0.fields.summary.range(of: expression, options: .regularExpression) != nil
                }?.key
            case let .failure(failure):
                if Env.current.debug {
                    Env.current.shell.write("\(failure)")
                }
                keyOfIssueToOpen = nil
            }
        } else {
            keyOfIssueToOpen = getIssueKey(from: issueKey)
        }

        guard var keyToOpen = keyOfIssueToOpen else { return false }

        if openParent {
            if let key = GetIssue(issueKey: keyToOpen).awaitResponseWithDebugPrinting()?.fields.parent?.key {
                keyToOpen = key
            } else {
                Env.current.shell.write("No parent found. Will open \(keyToOpen) instead.")
            }
        }

        guard let host = Env.current.jira.host,
            let url = URL(string: "https://\(host)/browse/\(keyToOpen)") else { return false }

        return Env.current.workspace.open(url)
    }
}
