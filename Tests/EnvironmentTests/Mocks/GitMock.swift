import Environment

class GitMock: Git {
    var conflictedFilesCallback = { [String]() }
    var conflictedFiles: [String] {
        return conflictedFilesCallback()
    }

    var currentBranchCallback = { String?.none }
    var currentBranch: String? {
        return currentBranchCallback()
    }

    var currentRepoCallback = { String?.none }
    var currentRepo: String? {
        return currentRepoCallback()
    }

    var currentServiceCallback = { GitService.stash }
    var currentService: GitService {
        return currentServiceCallback()
    }

    var domainCallback = { String?.none }
    var domain: String? {
        return domainCallback()
    }

    var hostCallback = { String?.none }
    var host: String? {
        return hostCallback()
    }

    var isRepoCallback = { false }
    var isRepo: Bool {
        return isRepoCallback()
    }

    var projectOrUserCallback = { String?.none }
    var projectOrUser: String? {
        return projectOrUserCallback()
    }

    var rootDirectoryCallback = { String?.none }
    var rootDirectory: String? {
        return rootDirectoryCallback()
    }

    var stagedFilesCallback = { String?.none }
    var stagedFiles: String? {
        return stagedFilesCallback()
    }

    var addCallback: ([String]) -> Bool = { _ in false }
    func add(_ files: [String]) -> Bool {
        return addCallback(files)
    }

    var branchesWithExcludeCurrentCallback: (GitBranchType, Bool) -> [String] = { _, _ in [] }
    func branches(_ branchType: GitBranchType, excludeCurrent: Bool) -> [String] {
        return branchesWithExcludeCurrentCallback(branchType, excludeCurrent)
    }

    var branchesContainingWithOptionsAndExcludeCurrentCallback: (String, String.CompareOptions, Bool) -> [String] = { _, _, _ in [] }
    func branches(containing: String, options: String.CompareOptions, excludeCurrent: Bool) -> [String] {
        return branchesContainingWithOptionsAndExcludeCurrentCallback(containing, options, excludeCurrent)
    }

    var checkoutCallback: (String) -> Bool = { _ in false }
    func checkout(_ branch: String) -> Bool {
        return checkoutCallback(branch)
    }

    var commitCallback: (String) -> Bool = { _ in false }
    func commit(message: String) -> Bool {
        return commitCallback(message)
    }

    var createBranchCallback: (String) -> Bool = { _ in false }
    func createBranch(name: String) -> Bool {
        return createBranchCallback(name)
    }

    var deleteLocalCallback: (String, Bool) -> Bool = { _, _ in false }
    func deleteLocal(branch: String, forced: Bool) -> Bool {
        return deleteLocalCallback(branch, forced)
    }

    var deleteRemoteCallback: (String) -> Bool = { _ in false }
    func deleteRemote(branch: String) -> Bool {
        return deleteRemoteCallback(branch)
    }

    var fetchCallback = { false }
    func fetch() -> Bool {
        return fetchCallback()
    }

    var listFilesCallback: ([GitFileType]) -> [String] = { _ in [] }
    func listFiles(_ fileTypes: [GitFileType]) -> [String] {
        return listFilesCallback(fileTypes)
    }

    var mergeCallback: (String) -> Bool = { _ in false }
    func merge(_ branch: String) -> Bool {
        return mergeCallback(branch)
    }

    var pullCallback = { false }
    func pull() -> Bool {
        return pullCallback()
    }

    var pushCallback = { false }
    func push() -> Bool {
        return pushCallback()
    }

    var pushSetUpstreamCallback = { false }
    func pushSetUpstream() -> Bool {
        return pushSetUpstreamCallback()
    }

    var renameCurrentBranchCallback: (String) -> Bool = { _ in false }
    func renameCurrentBranch(newName: String) -> Bool {
        return renameCurrentBranchCallback(newName)
    }

    var stagedDiffCallback: (UInt) -> String? = { _ in nil }
    func stagedDiff(linesOfContext: UInt) -> String? {
        return stagedDiffCallback(linesOfContext)
    }

    var statusCallback: (Bool) -> String? = { _ in nil }
    func status(verbose: Bool) -> String? {
        return statusCallback(verbose)
    }
}
