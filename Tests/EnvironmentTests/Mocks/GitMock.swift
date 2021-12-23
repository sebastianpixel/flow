import Environment

class GitMock: Git {
    var conflictedFilesCallback = { [String]() }
    var conflictedFiles: [String] {
        conflictedFilesCallback()
    }

    var currentBranchCallback = { String?.none }
    var currentBranch: String? {
        currentBranchCallback()
    }

    var currentRepoCallback = { String?.none }
    var currentRepo: String? {
        currentRepoCallback()
    }

    var currentServiceCallback = { GitService.stash }
    var currentService: GitService {
        currentServiceCallback()
    }

    var domainCallback = { String?.none }
    var domain: String? {
        domainCallback()
    }

    var hostCallback = { String?.none }
    var host: String? {
        hostCallback()
    }

    var isRepoCallback = { false }
    var isRepo: Bool {
        isRepoCallback()
    }

    var logCallback = { [GitCommit]() }
    var log: [GitCommit] {
        logCallback()
    }

    var projectOrUserCallback = { String?.none }
    var projectOrUser: String? {
        projectOrUserCallback()
    }

    var rootDirectoryCallback = { String?.none }
    var rootDirectory: String? {
        rootDirectoryCallback()
    }

    var stagedFilesCallback = { [String]() }
    var stagedFiles: [String] {
        stagedFilesCallback()
    }

    var addCallback: ([String]) -> Bool = { _ in false }
    func add(_ files: [String]) -> Bool {
        addCallback(files)
    }

    var branchesWithExcludeCurrentCallback: (GitBranchType, Bool) -> [String] = { _, _ in [] }
    func branches(_ branchType: GitBranchType, excludeCurrent: Bool) -> [String] {
        branchesWithExcludeCurrentCallback(branchType, excludeCurrent)
    }

    var branchesContainingWithOptionsAndExcludeCurrentCallback: (String, String.CompareOptions, Bool) -> [String] = { _, _, _ in [] }
    func branches(containing: String, options: String.CompareOptions, excludeCurrent: Bool) -> [String] {
        branchesContainingWithOptionsAndExcludeCurrentCallback(containing, options, excludeCurrent)
    }

    var checkoutCallback: (String) -> Bool = { _ in false }
    func checkout(_ branch: String) -> Bool {
        checkoutCallback(branch)
    }

    var commitCallback: (String) -> Bool = { _ in false }
    func commit(message: String) -> Bool {
        commitCallback(message)
    }

    var createBranchCallback: (String) -> Bool = { _ in false }
    func createBranch(name: String) -> Bool {
        createBranchCallback(name)
    }

    var deleteLocalCallback: (String, Bool) -> Bool = { _, _ in false }
    func deleteLocal(branch: String, forced: Bool) -> Bool {
        deleteLocalCallback(branch, forced)
    }

    var deleteRemoteCallback: (String) -> Bool = { _ in false }
    func deleteRemote(branch: String) -> Bool {
        deleteRemoteCallback(branch)
    }

    var fetchCallback: (Bool) -> Bool = { _ in false }
    func fetch(prune: Bool) -> Bool {
        fetchCallback(prune)
    }

    var listFilesCallback: ([GitFileType]) -> [String] = { _ in [] }
    func listFiles(_ fileTypes: [GitFileType]) -> [String] {
        listFilesCallback(fileTypes)
    }

    var mergeCallback: (String) -> Bool = { _ in false }
    func merge(_ branch: String) -> Bool {
        mergeCallback(branch)
    }

    var rebaseCallback: (String) -> Bool = { _ in false }
    func rebase(_ branch: String) -> Bool {
        rebaseCallback(branch)
    }

    var pullCallback = { false }
    func pull() -> Bool {
        pullCallback()
    }

    var pushCallback = { false }
    func push() -> Bool {
        pushCallback()
    }

    var pushSetUpstreamCallback = { false }
    func pushSetUpstream() -> Bool {
        pushSetUpstreamCallback()
    }

    var renameCurrentBranchCallback: (String) -> Bool = { _ in false }
    func renameCurrentBranch(newName: String) -> Bool {
        renameCurrentBranchCallback(newName)
    }

    var resetCallback: (String) -> Bool = { _ in false }
    func reset(_ file: String) -> Bool {
        resetCallback(file)
    }

    var revertCallback: (GitCommit) -> Bool = { _ in false }
    func revert(_ commit: GitCommit) -> Bool {
        revertCallback(commit)
    }

    var stagedDiffCallback: (UInt) -> String? = { _ in nil }
    func stagedDiff(linesOfContext: UInt) -> String? {
        stagedDiffCallback(linesOfContext)
    }

    var statusCallback: (Bool) -> String? = { _ in nil }
    func status(verbose: Bool) -> String? {
        statusCallback(verbose)
    }

    var cherryPickCallback: (GitCommit) -> Bool = { _ in false }
    func cherryPick(_ commit: GitCommit) -> Bool {
        cherryPickCallback(commit)
    }

    var differenceCallback: (String, String) -> (additionsInA: [GitCommit], additionsInB: [GitCommit]) = { _, _ in ([], []) }
    func difference(of branchA: String, to branchB: String) -> (additionsInA: [GitCommit], additionsInB: [GitCommit]) {
        return differenceCallback(branchA, branchB)
    }
}
