@testable import Environment
import XCTest

class GitTests: XCTestCase {
    let git = GitImpl()
    var shell: ShellMock { Env.current.shell as! ShellMock }
    var remote = GitService.stash.remote

    var commands = [String]()
    var prompts = [String]()

    var booleanReturn = [Bool]()
    var stringReturn = [String]()

    override func setUp() {
        super.setUp()

        Env.current = .mock

        shell.runReturningStringCallback = {
            self.commands.append($0)
            switch $0 {
            case "git remote -v":
                return """
                origin    \(self.remote) (fetch)
                origin    \(self.remote) (push)
                """
            case "git rev-parse --show-toplevel":
                return "/Users/user/projects/repo"
            default:
                return nil
            }
        }

        shell.runForegroundTaskCallback = {
            self.commands.append($0)
            return self.booleanReturn.removeFirst()
        }

        shell.runReturningBoolCallback = shell.runForegroundTaskCallback

        shell.promptDecisionCallback = {
            self.prompts.append($0)
            return self.booleanReturn.removeFirst()
        }

        shell.promptCallback = {
            self.prompts.append($0)
            return self.stringReturn.removeFirst()
        }
    }

    func testRemote() {
        let remote = git.remote

        XCTAssertEqual(remote?.domain, "company.com")
        XCTAssertEqual(remote?.pathComponents.count, 2)
        XCTAssertEqual(remote?.pathComponents[0], "project")
        XCTAssertEqual(remote?.pathComponents[1], "repo")
    }

    func testRemoteIsCached() {
        XCTAssertEqual(git.remote?.domain, "company.com")
        remote = GitService.github.remote
        XCTAssertEqual(git.remote?.domain, "company.com")
        XCTAssertNotEqual(GitImpl().remote?.domain, "company.com")
    }

    func testDomainOnlyReturnsTopAndSecondLevel() {
        remote = "https://user@subdomain.company.com/project/repo.git"
        XCTAssertEqual(git.domain, "company.com")
    }

    func testCurrentService() {
        for service in [GitService.github, .bitbucket, .stash] {
            remote = service.remote
            XCTAssertEqual(GitImpl().currentService, service)
        }
    }

    func testHost() {
        for service in [GitService.github, .bitbucket, .stash] {
            remote = service.remote
            XCTAssertEqual(GitImpl().host, service.host)
        }
    }

    func testProjectOrUser() {
        XCTAssertEqual(git.projectOrUser, "project")
    }

    func testRootDirectory() {
        XCTAssertEqual(git.rootDirectory, "/Users/user/projects/repo")
        XCTAssertEqual(commands.last, "git rev-parse --show-toplevel")
    }

    func testCurrentRepo() {
        XCTAssertEqual(git.currentRepo, "repo")
        XCTAssertEqual(commands.last, "git rev-parse --show-toplevel")
    }

    func testFiles() {
        shell.runReturningStringCallback = {
            self.self.commands.append($0)
            return "file1\nfile2\nfile3"
        }
        var files = git.listFiles([.unstaged])
        XCTAssertEqual(commands.last, "git ls-files --exclude-standard --full-name --modified")
        XCTAssertEqual(files, ["file1", "file2", "file3"])

        files = git.listFiles([.untracked])
        XCTAssertEqual(commands.last, "git ls-files --exclude-standard --full-name --others")

        files = git.listFiles([.unstaged, .untracked])
        XCTAssertEqual(commands.last, "git ls-files --exclude-standard --full-name --modified --others")

        files = git.listFiles([])
        XCTAssertEqual(commands.last, "git ls-files --exclude-standard --full-name")
    }

    func testAdd() {
        booleanReturn = [true]
        _ = git.add(["file with unescaped spaces", #"file with escaped spaces"#, "file_without_spaces"])

        XCTAssertEqual(commands.last, #"git add file\ with\ unescaped\ spaces file\ with\ escaped\ spaces file_without_spaces"#)
    }

    func testBranches() {
        booleanReturn = [true]
        shell.runReturningStringCallback = {
            self.commands.append($0)
            return """
            project/branch
            myBranch
            * master
            remotes/fork/myBranch
            remotes/origin/HEAD -> origin/master
            remotes/origin/master
            """
        }

        var branches = git.branches(.all)
        XCTAssertEqual(commands.last, "git branch --sort=-committerdate --all")
        XCTAssertEqual(branches, ["project/branch", "myBranch", "master"])

        branches = git.branches(.local)
        XCTAssertEqual(commands.last, "git branch --sort=-committerdate --list")

        branches = git.branches(.merged)
        XCTAssertEqual(commands.last, "git branch --sort=-committerdate --merged")

        branches = git.branches(.unmerged)
        XCTAssertEqual(commands.last, "git branch --sort=-committerdate --no-merged")
    }

    func testBranchesExcludeCurrent() {
        booleanReturn = [true, true]
        shell.runReturningStringCallback = {
            switch $0 {
            case "git rev-parse --abbrev-ref HEAD":
                return "master"
            case "git branch --sort=-committerdate --all":
                return "master\ndevelop"
            default:
                return nil
            }
        }

        var branches = git.branches(.all, excludeCurrent: true)
        XCTAssertEqual(branches, ["develop"])

        branches = git.branches(.all, excludeCurrent: false)
        XCTAssertEqual(branches, ["master", "develop"])
    }

    func testConflictedFiles() {
        shell.runReturningStringCallback = {
            self.commands.append($0)
            return "file1\nfile2\nfile3"
        }

        let files = git.conflictedFiles
        XCTAssertEqual(commands.first, "git diff --name-only --diff-filter=U")
        XCTAssertEqual(files, ["file1", "file2", "file3"])
    }

    func testDeleteLocal() {
        booleanReturn = [true]
        _ = git.deleteLocal(branch: "myBranch", forced: true)
        XCTAssertEqual(commands.last, "git branch -D myBranch")

        booleanReturn = [true]
        _ = git.deleteLocal(branch: "myBranch", forced: false)
        XCTAssertEqual(commands.last, "git branch -d myBranch")
    }

    func testDeleteRemote() {
        booleanReturn = [true]
        _ = git.deleteRemote(branch: "myBranch")
        XCTAssertEqual(commands.last, "git push origin :myBranch")
    }

    func testBranchesContainingPattern() {
        booleanReturn = [true]
        var branchList = ""
        shell.runReturningStringCallback = {
            self.commands.append($0)
            return branchList
        }

        branchList = #"""
        branch with spaces
        branchWithout
        """#
        let branches = git.branches(containing: "\\s", options: .regularExpression, excludeCurrent: true)
        XCTAssertEqual(branches, ["branch with spaces"])
    }

    func testIsRepo() {
        booleanReturn = [true]
        _ = git.isRepo
        XCTAssertEqual(commands.last, "git rev-parse")
    }

    func testRemotes() {
        _ = git.remotes
        XCTAssertEqual(commands.last, "git remote -v")
    }

    func testCurrentBranch() {
        _ = git.currentBranch
        XCTAssertEqual(commands.last, "git rev-parse --abbrev-ref HEAD")
    }

    func testStagedDiff() {
        _ = git.stagedDiff(linesOfContext: 99)
        XCTAssertEqual(commands.last, "git diff --staged --unified=99")
    }

    func testStagedFiles() {
        _ = git.stagedFiles
        XCTAssertEqual(commands.last, "git diff --staged --name-only")
    }

    func testStatus() {
        _ = git.status(verbose: true)
        XCTAssertEqual(commands.last, "git status --verbose")

        _ = git.status(verbose: false)
        XCTAssertEqual(commands.last, "git status")
    }

    func testPush() {
        booleanReturn = [true]
        _ = git.push()
        XCTAssertEqual(commands.last, "git push")
    }

    func testFetch() {
        booleanReturn = [true]
        _ = git.fetch()
        XCTAssertEqual(commands.last, "git fetch")
    }

    func testPull() {
        booleanReturn = [true]
        _ = git.pull()
        XCTAssertEqual(commands.last, "git pull")
    }

    func testMerge() {
        booleanReturn = [true]
        _ = git.merge("myBranch")
        XCTAssertEqual(commands.last, "git merge myBranch")
    }

    func testPushSetUpstream() {
        booleanReturn = [true]
        _ = git.pushSetUpstream()
        XCTAssertEqual(commands.last, "git rev-parse --abbrev-ref HEAD")
    }

    func testCommit() {
        booleanReturn = [true]
        _ = git.commit(message: "message goes here")
        XCTAssertEqual(commands.last, "git commit -m \"message goes here\"")
    }

    func testCreateBranchSucceedsAtFirstAttempt() {
        booleanReturn = [true]
        _ = git.createBranch(name: "myBranch")
        XCTAssertEqual(commands.last, "git checkout -b myBranch")
    }

    func testCreateBranchFailsWithoutRetry() {
        booleanReturn = [false, false]
        _ = git.createBranch(name: "myBranch")
        XCTAssertEqual(commands, ["git checkout -b myBranch"])
        XCTAssertEqual(prompts, ["Want to enter another branch name?"])
    }

    func testCreateBranchFailsWithFailedRetry() {
        booleanReturn = [false, true, false, false]
        stringReturn = ["myOtherBranch"]

        _ = git.createBranch(name: "myBranch")
        XCTAssertEqual(commands, ["git checkout -b myBranch", "git checkout -b myOtherBranch"])
        XCTAssertEqual(prompts, ["Want to enter another branch name?", "", "Want to enter another branch name?"])
    }

    func testCreateBranchSucceedsOnRetry() {
        booleanReturn = [false, true, false, true, true]
        stringReturn = ["myOtherBranch", "myWholeOtherBranch"]

        _ = git.createBranch(name: "myBranch")
        XCTAssertEqual(commands, ["git checkout -b myBranch", "git checkout -b myOtherBranch", "git checkout -b myWholeOtherBranch"])
        XCTAssertEqual(prompts, ["Want to enter another branch name?", "", "Want to enter another branch name?", ""])
    }

    func testCheckout() {
        booleanReturn = [true]
        _ = git.checkout("myBranch")
        XCTAssertEqual(commands.last, "git checkout myBranch")
    }

    func testRenameCurrentBranch() {
        booleanReturn = [true]
        _ = git.renameCurrentBranch(newName: "myOtherBranch")
        XCTAssertEqual(commands.last, "git branch -m myOtherBranch")
    }

    func testCherryPick() {
        booleanReturn = [true]
        _ = git.cherryPick(.init(shortHash: "shortHash", subject: "subject", isMergeCommit: false))
        XCTAssertEqual(commands.last, "git cherry-pick shortHash")
    }

    func testDifference() {
        booleanReturn = [true]
        _ = git.difference(of: "branchA", to: "branchB")
        XCTAssertEqual(commands.last, "git --no-pager log --cherry-pick --oneline branchA...branchB --left-right --no-merges --no-color --pretty=format:\"%m_section_%h_section_%s\"")
    }

    func testLog() {
        booleanReturn = [true]
        _ = git.log
        XCTAssertEqual(commands.last, "git --no-pager log --oneline --pretty=format:\"%h_section_%s_section_%P\"")
    }

    func testRevertNonMergeCommit() {
        booleanReturn = [true]
        _ = git.revert(.init(shortHash: "shortHash", subject: "subject", isMergeCommit: false))
        XCTAssertEqual(commands.last, "git revert shortHash")
    }

    func testRevertMergeCommit() {
        booleanReturn = [true]
        _ = git.revert(.init(shortHash: "shortHash", subject: "subject", isMergeCommit: true))
        XCTAssertEqual(commands.last, "git revert -m 1 shortHash")
    }

    func testReset() {
        booleanReturn = [true]
        _ = git.reset("/path/to/file")
        XCTAssertEqual(commands.last, "git reset \("/path/to/file")")
    }
}

extension GitService {
    var remote: String {
        switch self {
        case .bitbucket:
            return "https://user@bitbucket.org/project/repo.git"
        case .github:
            return "https://github.com/project/repo.git"
        default:
            return "https://user@company.com/project/repo.git"
        }
    }

    var host: String {
        switch self {
        case .bitbucket:
            return "bitbucket.org"
        case .github:
            return "github.com"
        case .stash:
            return "stash.company.com"
        }
    }
}
