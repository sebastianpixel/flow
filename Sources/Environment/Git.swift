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
    var log: [GitCommit] { get }

    func add(_ files: [String]) -> Bool
    func branches(_ branchType: GitBranchType, excludeCurrent: Bool) -> [String]
    func branches(containing: String, options: String.CompareOptions, excludeCurrent: Bool) -> [String]
    func checkout(_ branchOrFile: String) -> Bool
    func cherryPick(_ commit: GitCommit) -> Bool
    func commit(message: String) -> Bool
    func createBranch(name: String) -> Bool
    func deleteLocal(branch: String, forced: Bool) -> Bool
    func deleteRemote(branch: String) -> Bool
    func difference(of branchA: String, to branchB: String) -> (additionsInA: [GitCommit], additionsInB: [GitCommit])
    func fetch() -> Bool
    func listFiles(_ fileTypes: [GitFileType]) -> [String]
    func merge(_ branch: String) -> Bool
    func pull() -> Bool
    func push() -> Bool
    func pushSetUpstream() -> Bool
    func renameCurrentBranch(newName: String) -> Bool
    func revert(_ commit: GitCommit) -> Bool
    func stagedDiff(linesOfContext: UInt) -> String?
    func status(verbose: Bool) -> String?
}

public extension Git {
    func branches(containing pattern: String) -> [String] {
        branches(containing: pattern, options: [], excludeCurrent: true)
    }

    func branches(_ branchType: GitBranchType) -> [String] {
        branches(branchType, excludeCurrent: true)
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

public struct GitCommit: Equatable {
    public let shortHash, subject: String
    public let isMergeCommit: Bool
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
        remote?.domain
    }

    var host: String? {
        if currentService == .stash {
            return (remote?.domain).map { "stash.\($0)" }
        } else {
            return remote?.domain
        }
    }

    var projectOrUser: String? {
        remote?.pathComponents.first
    }

    var currentRepo: String? {
        rootDirectory.map(URL.init(fileURLWithPath:))?.lastPathComponent
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
        if branchType == .all {
            _ = fetch()
        }
        let cmd = "git branch --sort=-committerdate \(branchType.flag)"
        let currentBranch = self.currentBranch
        guard let output = Env.current.shell.run(cmd) else { return [] }

        let branches = output
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: #"^(\*\s|\s*remotes/origin/|\s*remotes/fork/)"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.contains("HEAD") && (excludeCurrent ? ($0 != currentBranch) : true) }

        var set = Set<String>()
        return branches.reduce(into: [String]()) { branches, branch in
            if set.insert(branch).inserted {
                branches.append(branch)
            }
        }
    }

    var conflictedFiles: [String] {
        Env.current.shell.run("git diff --name-only --diff-filter=U")?
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty } ?? []
    }

    func deleteLocal(branch: String, forced: Bool) -> Bool {
        Env.current.shell.run("git branch -\(forced ? "D" : "d") \(branch)")
    }

    func deleteRemote(branch: String) -> Bool {
        Env.current.shell.run("git push origin :\(branch)")
    }

    func difference(of branchA: String, to branchB: String) -> (additionsInA: [GitCommit], additionsInB: [GitCommit]) {
        let markerForSplitting = "_section_"
        var additionsInA = [GitCommit]()
        var additionsInB = [GitCommit]()

        Env.current.shell.run("git --no-pager log --cherry-pick --oneline \(branchA)...\(branchB) --left-right --no-merges --no-color --pretty=format:\"%m\(markerForSplitting)%h\(markerForSplitting)%s\"")?
            .components(separatedBy: .newlines)
            .lazy
            .map { $0.components(separatedBy: markerForSplitting) }
            .filter { $0.count == 3 }
            .forEach {
                let commit = GitCommit(shortHash: $0[1], subject: $0[2], isMergeCommit: false)
                switch $0[0] {
                case "<": additionsInA.append(commit)
                case ">": additionsInB.append(commit)
                default: return
                }
            }

        return (additionsInA, additionsInB)
    }

    func branches(containing pattern: String, options: String.CompareOptions, excludeCurrent: Bool) -> [String] {
        branches(.all, excludeCurrent: excludeCurrent).filter { $0.range(of: pattern, options: options) != nil }
    }

    var isRepo: Bool {
        Env.current.shell.run("git rev-parse")
    }

    var remotes: String? {
        Env.current.shell.run("git remote -v")
    }

    var rootDirectory: String? {
        Env.current.shell.run("git rev-parse --show-toplevel")
    }

    var currentBranch: String? {
        Env.current.shell.run("git rev-parse --abbrev-ref HEAD")
    }

    func stagedDiff(linesOfContext: UInt) -> String? {
        Env.current.shell.run("git diff --staged --unified=\(linesOfContext)")
    }

    var stagedFiles: String? {
        Env.current.shell.run("git diff --staged --name-only")
    }

    var log: [GitCommit] {
        let markerForSplitting = "_section_"
        return Env.current.shell.run("git --no-pager log --oneline --pretty=format:\"%h\(markerForSplitting)%s\(markerForSplitting)%P\"")?
            .components(separatedBy: .newlines)
            .lazy
            .map { $0.components(separatedBy: markerForSplitting) }
            .filter { $0.count == 3 }
            .map { GitCommit(shortHash: $0[0], subject: $0[1], isMergeCommit: $0[2].components(separatedBy: .whitespaces).count > 1) }
            ?? []
    }

    func status(verbose: Bool) -> String? {
        Env.current.shell.run("git status\(verbose ? " --verbose" : "")")
    }

    func push() -> Bool {
        Env.current.shell.runForegroundTask("git push")
    }

    func fetch() -> Bool {
        Env.current.shell.runForegroundTask("git fetch")
    }

    func pull() -> Bool {
        Env.current.shell.runForegroundTask("git pull")
    }

    func merge(_ branch: String) -> Bool {
        Env.current.shell.runForegroundTask("git merge \(branch)")
    }

    func pushSetUpstream() -> Bool {
        currentBranch.map { Env.current.shell.runForegroundTask("git push --set-upstream origin \($0)") } ?? false
    }

    func commit(message: String) -> Bool {
        Env.current.shell.runForegroundTask("git commit -m \"\(message)\"")
    }

    func createBranch(name: String) -> Bool {
        Env.current.shell.run("git checkout -b \(name)")
    }

    func cherryPick(_ commit: GitCommit) -> Bool {
        Env.current.shell.run("git cherry-pick \(commit.shortHash)")
    }

    func checkout(_ branchOrFile: String) -> Bool {
        Env.current.shell.run("git checkout \(branchOrFile)")
    }

    func renameCurrentBranch(newName: String) -> Bool {
        Env.current.shell.run("git branch -m \(newName)")
    }

    func revert(_ commit: GitCommit) -> Bool {
        Env.current.shell.runForegroundTask("git revert \(commit.isMergeCommit ? "-m 1 " : "")\(commit.shortHash)")
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
