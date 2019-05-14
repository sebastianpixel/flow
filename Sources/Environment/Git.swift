import Foundation
import Utils

public protocol Git {
    var conflictedFiles: [String] { get }
    var currentBranch: String? { get }
    var currentRepo: String? { get }
    var currentService: GitService { get }
    var domain: String? { get }
    var host: String? { get }
    var isRepo: Bool { get }
    var projectOrUser: String? { get }
    var rootDirectory: String? { get }
    var stagedFiles: String? { get }

    func add(_ files: [String]) -> Bool
    func branches(_ branchType: GitBranchType, excludeCurrent: Bool) -> [String]
    func branches(containing: String, options: String.CompareOptions) -> [String]
    func checkout(_ branch: String) -> Bool
    func commit(message: String) -> Bool
    func createBranch(name: String) -> Bool
    func deleteLocal(branch: String, forced: Bool) -> Bool
    func deleteRemote(branch: String) -> Bool
    func fetch() -> Bool
    func listFiles(_ fileTypes: [GitFileType]) -> [String]
    func merge(_ branch: String) -> Bool
    func pull() -> Bool
    func push() -> Bool
    func pushSetUpstream() -> Bool
    func renameCurrentBranch(newName: String) -> Bool
    func stagedDiff(linesOfContext: UInt) -> String?
    func status(verbose: Bool) -> String?
}

public extension Git {
    func branches(containing pattern: String) -> [String] {
        return branches(containing: pattern, options: [])
    }

    func branches(_ branchType: GitBranchType) -> [String] {
        return branches(branchType, excludeCurrent: true)
    }
}

public enum GitService {
    case bitbucket, stash, github
}

public enum GitBranchType {
    case local, all, merged, unmerged

    var flag: String {
        let flag: String
        switch self {
        case .local: flag = "list"
        case .all: flag = "all"
        case .merged: flag = "merged"
        case .unmerged: flag = "no-merged"
        }
        return "--\(flag)"
    }
}

public enum GitFileType {
    case unstaged, untracked

    var flag: String {
        let flag: String
        switch self {
        case .unstaged: flag = "modified"
        case .untracked: flag = "others"
        }
        return "--\(flag)"
    }
}

class GitImpl: Git {
    var domain: String? {
        return remote?.domain
    }

    var host: String? {
        if currentService == .stash {
            return (remote?.domain).map { "stash.\($0)" }
        } else {
            return remote?.domain
        }
    }

    var projectOrUser: String? {
        return remote?.pathComponents.first
    }

    var currentRepo: String? {
        return rootDirectory.map(URL.init(fileURLWithPath:))?.lastPathComponent
    }

    var currentService: GitService {
        let domain = self.domain
        if domain?.contains("github") == true {
            return .github
        } else if domain?.contains("bitbucket") == true {
            return .bitbucket
        } else {
            return .stash
        }
    }

    func listFiles(_ fileTypes: [GitFileType]) -> [String] {
        let cmd = "git ls-files --exclude-standard --full-name \(fileTypes.map { $0.flag }.joined(separator: " "))".trimmingCharacters(in: .whitespaces)
        return Env.current.shell.run(cmd)?
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty } ?? []
    }

    func add(_ files: [String]) -> Bool {
        let joined = files
            .map { $0.replacingOccurrences(of: "\\s", with: "\\\\ ", options: .regularExpression) }
            .joined(separator: " ")
        return Env.current.shell.runForegroundTask("git add \(joined)")
    }

    func branches(_ branchType: GitBranchType, excludeCurrent: Bool) -> [String] {
        let cmd = "git branch --sort=-committerdate \(branchType.flag)"
        let currentBranch = self.currentBranch
        return (Env.current.shell.run(cmd)?
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: #"^(\*\s|\s*remotes/origin/|\s*remotes/fork/)"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.contains("HEAD") && (excludeCurrent ? ($0 != currentBranch) : true) })
            .flatMap { NSOrderedSet(array: $0).array as? [String] } ?? []
    }

    var conflictedFiles: [String] {
        return Env.current.shell.run("git diff --name-only --diff-filter=U")?
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty } ?? []
    }

    func deleteLocal(branch: String, forced: Bool) -> Bool {
        return Env.current.shell.run("git branch -\(forced ? "D" : "d") \(branch)")
    }

    func deleteRemote(branch: String) -> Bool {
        return Env.current.shell.run("git push origin :\(branch)")
    }

    func branches(containing pattern: String, options: String.CompareOptions) -> [String] {
        return branches(.all, excludeCurrent: false).filter { $0.range(of: pattern, options: options) != nil }
    }

    var isRepo: Bool {
        return Env.current.shell.run("git rev-parse")
    }

    var remotes: String? {
        return Env.current.shell.run("git remote -v")
    }

    var rootDirectory: String? {
        return Env.current.shell.run("git rev-parse --show-toplevel")
    }

    var currentBranch: String? {
        return Env.current.shell.run("git rev-parse --abbrev-ref HEAD")
    }

    func stagedDiff(linesOfContext: UInt) -> String? {
        return Env.current.shell.run("git diff --staged --unified=\(linesOfContext)")
    }

    var stagedFiles: String? {
        return Env.current.shell.run("git diff --staged --name-only")
    }

    func status(verbose: Bool) -> String? {
        return Env.current.shell.run("git status\(verbose ? " --verbose" : "")")
    }

    func push() -> Bool {
        return Env.current.shell.runForegroundTask("git push")
    }

    func fetch() -> Bool {
        return Env.current.shell.runForegroundTask("git fetch")
    }

    func pull() -> Bool {
        return Env.current.shell.runForegroundTask("git pull")
    }

    func merge(_ branch: String) -> Bool {
        return Env.current.shell.runForegroundTask("git merge \(branch)")
    }

    func pushSetUpstream() -> Bool {
        return currentBranch.map { Env.current.shell.runForegroundTask("git push --set-upstream origin \($0)") } ?? false
    }

    func commit(message: String) -> Bool {
        return Env.current.shell.runForegroundTask("git commit -m \"\(message)\"")
    }

    func createBranch(name: String) -> Bool {
        if !Env.current.shell.runForegroundTask("git checkout -b \(name)") {
            if Env.current.shell.promptDecision("Want to enter another branch name?"),
                let newName = Env.current.shell.prompt("") {
                return createBranch(name: newName)
            } else {
                return false
            }
        }
        return true
    }

    func checkout(_ branch: String) -> Bool {
        return Env.current.shell.run("git checkout \(branch)")
    }

    func renameCurrentBranch(newName: String) -> Bool {
        return Env.current.shell.run("git branch -m \(newName)")
    }

    var remoteCache: (String, [String])?

    var remote: (domain: String, pathComponents: [String])? {
        if let remoteCache = remoteCache {
            return remoteCache
        }

        let urlRegex = NSRegularExpression("^[[:word:]]*[[:blank:]]*([[:word:]]*://[^@]*@?[[:graph:]]*?)\\.git")

        guard
            let remote = remotes?.components(separatedBy: .newlines).first,
            let match = urlRegex.firstMatch(in: remote, range: .init(location: 0, length: remote.utf16.count)),
            match.numberOfRanges == 2,
            let urlRange = Range(match.range(at: 1), in: remote),
            let components = URLComponents(string: String(remote[urlRange])),
            let host = components.host?.components(separatedBy: .punctuationCharacters),
            let firstLevelDomain = host.last,
            let secondLevelDomain = host.dropLast().last
        else { return nil }

        let domain = [secondLevelDomain, firstLevelDomain].joined(separator: ".")

        let path = components.path
            .components(separatedBy: "/")
            .filter { $0 != "/" && !$0.isEmpty }

        remoteCache = (domain, path)

        return (domain, path)
    }
}
