import Environment
import Foundation
import Request
import UI

public struct BrowseGit: Procedure {
    public enum Branch {
        case current, parent, expression(String), issue(String)
    }

    private let currentDirectory, pullRequest: Bool
    private let branchToOpen: Branch

    public init(currentDirectory: Bool, pullRequest: Bool, branchToOpen: Branch) {
        self.currentDirectory = currentDirectory
        self.pullRequest = pullRequest
        self.branchToOpen = branchToOpen
    }

    public func run() -> Bool {
        guard let branch: String = {
            switch branchToOpen {
            case .current:
                return Env.current.git.currentBranch
            case .parent:
                let currentIssue = Env.current.jira.currentIssueKey().map(GetIssue.init)?.awaitResponseWithDebugPrinting()
                let parentKey = currentIssue?.fields.parent?.key
                return parentKey.flatMap { Env.current.git.branch(containing: $0, excludeCurrent: true) }
            case let .expression(expression):
                return Env.current.git.branch(containing: expression, excludeCurrent: false, options: .regularExpression)
            case let .issue(issue):
                return getIssueKey(from: issue).flatMap { Env.current.git.branch(containing: $0, excludeCurrent: false) }
            }
        }() ?? Env.current.jira.currentIssueKey().flatMap({ Env.current.git.branch(containing: $0, excludeCurrent: false) }) else { return false }

        if pullRequest,
            let url = getUrlOfPullRequest(branch: branch)
        {
            return Env.current.workspace.open(url)
        }

        guard let host = Env.current.git.host else {
            Env.current.shell.write("Could not find remote repository.")
            return false
        }

        var directory: String?
        if currentDirectory,
            let rootDirectory = Env.current.git.rootDirectory
        {
            directory = FileManager.default.currentDirectoryPath
            directory?
                .range(of: rootDirectory)
                .map { directory?.removeSubrange($0) }
            if directory?.isEmpty == false {
                _ = directory?.removeFirst()
            }
        }

        let pathComponents: [String?]

        let repo = Env.current.git.currentRepo
        let project = Env.current.git.projectOrUser

        switch Env.current.git.currentService {
        case .stash:
            let tail = pullRequest
                ? ["pull-requests"]
                : ["browse", directory, "?at=refs%2Fheads%2F\(branch)"]
            pathComponents = ["projects", project?.uppercased(), "repos", repo] + tail

        case .bitbucket:
            let tail = pullRequest
                ? ["pull-requests"]
                : ["src", branch, directory]
            pathComponents = [project, repo] + tail

        case .github where pullRequest:
            pathComponents = ["pulls"]

        case .github:
            pathComponents = [project, repo, "tree", branch, directory]
        }

        let path = pathComponents.reduce(into: "") { path, component in
            guard let component = component else { return }
            path += "/\(component)"
        }

        guard let url = URL(string: "https://\(host)\(path)") else { return false }

        return Env.current.workspace.open(url)
    }
}
