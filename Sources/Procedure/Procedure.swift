import Environment
import Model
import Request
import UI
import Utils

public protocol Procedure {
    func run() -> Bool
}

extension Procedure {
    /// Tries to get a JIRA issue key from optional input that
    /// may already be the full key or only the issue number.
    func getIssueKey(from rawKey: String?) -> String? {
        return rawKey?.extracting(.jiraIssueKeyPattern)
            ?? rawKey?.extracting(.numbersPattern).flatMap { number -> String? in
                (Env.current.jira.currentProject ?? getProjectFromAllAvailable()).map { "\($0)-\(number)" }
                    ?? Env.current.git.branch(containing: number, excludeCurrent: false)?.extracting(.jiraIssueKeyPattern)
            }
            ?? Env.current.jira.currentIssueKey()
    }

    /// Get JIRA project from optional input or available fallbacks.
    func getJiraProject(from rawProject: String?) -> String? {
        guard let project = rawProject
            ?? Env.current.jira.currentProject
            ?? getProjectFromAllAvailable()
            ?? Env.current.shell.prompt("JIRA project"),
            !project.isEmpty else { return nil }
        return project
    }

    private func getProjectFromAllAvailable() -> String? {
        guard let projects = GetProjects().awaitResponseWithDebugPrinting() else { return nil }
        let dataSource = GenericLineSelectorDataSource(items: projects, line: \.description)
        return LineSelector(dataSource: dataSource)?.singleSelection()?.output?.key
    }

    func getCommitters(stashProject: String, repo: String) -> Future<Result<[User], Error>> {
        return GetLastCommits(stashProject: stashProject, repo: repo, limit: 250)
            .request()
            .map { result -> Result<[User], Error> in
                result.map { response -> [User] in
                    var set = Set<User>()
                    return response.values
                        .reduce(into: [User]()) { users, commit in
                            guard commit.committer.active, set.insert(commit.committer).inserted else { return }
                            users.append(commit.committer)
                        }
                        .sorted { $0.name > $1.name }
                }
            }
    }
}
