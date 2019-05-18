public protocol Jira {
    var host: String? { get }
    var currentProject: String? { get }
    func currentIssueKey(promptOnError: Bool) -> String?
}

public extension Jira {
    func currentIssueKey() -> String? {
        return currentIssueKey(promptOnError: true)
    }
}

struct JiraImpl: Jira {
    var currentProject: String? {
        return currentIssueKey(promptOnError: false)?.extracting(.uppercasesPattern)
    }

    func currentIssueKey(promptOnError: Bool) -> String? {
        if let key = Env.current.git.currentBranch.flatMap({ $0.extracting(.jiraIssueKeyPattern) }) {
            return key
        }
        guard promptOnError else { return nil }
        Env.current.shell.write("Could not retrieve key of current issue. Make sure you checked out a branch that has the key of a JIRA ticket in its name.")
        var key: String?
        if Env.current.shell.promptDecision("Want to enter a key?") {
            key = Env.current.shell.prompt("Format: <PROJECT-1234>")
        }
        return key?.extracting(.jiraIssueKeyPattern)
    }

    var host: String? {
        return Env.current.git.domain.map { "jira.\($0)" }
    }
}
