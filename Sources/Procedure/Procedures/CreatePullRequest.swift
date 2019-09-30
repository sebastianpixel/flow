import Environment
import Foundation
import Model
import Request
import UI
import Utils

public final class CreatePullRequest: Procedure {
    enum Error: Swift.Error {
        case
            noReviewersReceived,
            noBranchSelected,
            interactiveCommandFailed,
            noTitleProvided,
            noIssueKey,
            transitionNotFound(String),
            selfDeallocated
    }

    private let defaultReviewers: Bool
    private let parentBranch: Bool
    private let noEdit: Bool
    private let browseAfterSuccessfulCreation: Bool
    private let copyPRDescriptionToClipboard: Bool

    private var currentIssueKey = Env.current.jira.currentIssueKey(promptOnError: false)
    private lazy var currentIssue = { currentIssueKey.map(GetIssue.init)?.awaitResponseWithDebugPrinting() }()

    public init(defaultReviewers: Bool,
                parentBranch: Bool,
                noEdit: Bool,
                browseAfterSuccessfulCreation: Bool,
                copyPRDescriptionToClipboard: Bool) {
        self.defaultReviewers = defaultReviewers
        self.parentBranch = parentBranch
        self.noEdit = noEdit
        self.browseAfterSuccessfulCreation = browseAfterSuccessfulCreation
        self.copyPRDescriptionToClipboard = copyPRDescriptionToClipboard
    }

    public func run() -> Bool {
        guard let stashProject = Env.current.git.projectOrUser,
            let repo = Env.current.git.currentRepo,
            let currentBranch = Env.current.git.currentBranch else { return false }

        let result = Future.return(destinationBranch(parentBranch: parentBranch))
            .concat(reviewers(stashProject: stashProject, repo: repo, defaultReviewers: defaultReviewers))
            .map { branchResult, reviewersResult -> Result<(destinationBranch: String, reviewers: [String]), Swift.Error> in
                switch (branchResult, reviewersResult) {
                case let (.failure(failure), _), let (_, .failure(failure)):
                    return .failure(failure)
                case let (.success(destinationBranch), .success(reviewers)):
                    return .success((destinationBranch, reviewers))
                }
            }
            .await()
            .flatMap { [weak self] destinationBranch, reviewers -> Result<PostPullRequest.Response, Swift.Error> in
                guard let self = self else { return .failure(Error.selfDeallocated) }
                let title, description: String
                let defaultTitle = self.createDefaultTitle(from: currentBranch)
                if self.noEdit {
                    title = defaultTitle
                    description = ""
                } else {
                    switch self.promptToCreateTitleAndDescription(defaultTitle: defaultTitle) {
                    case let .success(success):
                        title = success.title
                        description = success.description
                    case let .failure(failure):
                        return .failure(failure)
                    }
                }
                let result = PostPullRequest(stashProject: stashProject,
                                       repository: repo,
                                       title: title,
                                       source: currentBranch,
                                       destination: destinationBranch,
                                       reviewers: reviewers,
                                       description: description,
                                       closeSourceBranch: true).request().await()
                if copyPRDescriptionToClipboard,
                    result.isSuccess,
                    let url = getUrlOfPullRequest(branch: currentBranch)?.absoluteString {
                    Env.current.clipboard.string = "PR \"\(title)\": \(url)"
                }
                return result
            }
            .flatMap { _ -> Result<(issueKey: String, response: GetIssueTransitions.Response), Swift.Error> in
                // No key in branch name nor key provided -> don't try to set new status
                guard let issueKey = currentIssueKey else {
                    return .failure(Error.noIssueKey)
                }

                return GetIssueTransitions(issueKey: issueKey).request().await().map { (issueKey, $0) }
            }
            .flatMap { issueKey, response -> Result<PostTransition.Response, Swift.Error> in
                if let transition = response.transitions.first(where: { $0.name == "Ready To Review" }) {
                    return PostTransition(issueKey: issueKey, transitionId: transition.id).request().await()
                }
                return .failure(Error.transitionNotFound("Ready to Review"))
            }

        switch result {
        case .success:
            if browseAfterSuccessfulCreation,
                let url = getUrlOfPullRequest(branch: currentBranch) {
                return Env.current.workspace.open(url)
            } else {
                return true
            }
        case let .failure(failure):
            if Env.current.debug {
                Env.current.shell.write("\(failure)")
            }
            switch failure {
            case let ApiClientError.status(_, bitbucketError?):
                Env.current.shell.write(bitbucketError.messagesConcatenated)
                return false
            case Error.noBranchSelected, Error.noIssueKey, Error.noTitleProvided:
                // User opt-out
                return true
            default:
                return false
            }
        }
    }

    struct StashError: Decodable {
        struct SingleStashError: Decodable {
            let message: String
            let exeptionName: String
        }
        let errors: [SingleStashError]
    }

    private func reviewers(stashProject: String, repo: String, defaultReviewers: Bool) -> Future<Result<[String], Swift.Error>> {
        var reviewers = Future.return(Result<[String], Swift.Error>.failure(Error.noReviewersReceived))
        if defaultReviewers {
            reviewers = GetDefaultReviewers(stashProject: stashProject, repo: repo)
                .request()
                .map { result -> Result<[String], Swift.Error> in
                    result.flatMap {
                        let username = Env.current.login.username
                        let names = $0.first?.reviewers.filter { $0.active == true && $0.name != username }.map { $0.name }
                        if let reviewers = names {
                            return .success(reviewers)
                        } else {
                            Env.current.shell.write("Could not retrieve default reviewers. Trying to get potential reviewers from previous commits…")
                            return .failure(Error.noReviewersReceived)
                        }
                    }
                }
        }

        return reviewers.flatMap { result -> Future<Result<[String], Swift.Error>> in
            switch result {
            case .success:
                return Future.return(result)
            case .failure:
                return
                    self.getCommitters(stashProject: stashProject, repo: repo).map { result in
                        result.flatMap { committers -> Result<[String], Swift.Error> in
                            if !committers.isEmpty,
                                let lineSelector = LineSelector(
                                    dataSource: GenericLineSelectorDataSource(
                                        items: committers
                                            .filter { $0.name != Env.current.login.username }
                                            .sorted { $0.name > $1.name },
                                        line: \.description)
                                ),
                                let selection = lineSelector.multiSelection() {
                                return .success(selection.output.map { $0.name })
                            } else {
                                return .failure(Error.noReviewersReceived)
                            }
                        }
                }
            }
        }
    }

    private func destinationBranch(parentBranch: Bool) -> Result<String, Swift.Error> {
        let allBranches = Env.current.git.branches(.all)
        var destinationBranch = Result<String, Swift.Error>.failure(Error.noBranchSelected)

        if parentBranch {
            if let currentIssue = currentIssue,
                let parentKey = currentIssue.fields.parent?.key,
                let parentBranch = allBranches.first(where: { $0.contains(parentKey) }) {
                destinationBranch = .success(parentBranch)
            } else {
                Env.current.shell.write("Could not find parent branch. Please choose one from the following:")
                destinationBranch = .failure(Error.noBranchSelected)
            }
        }

        return destinationBranch.flatMapError { error -> Result<String, Swift.Error> in
            let dataSource = GenericLineSelectorDataSource(items: allBranches)
            if let branch = LineSelector(dataSource: dataSource)?.singleSelection()?.output {
                return .success(branch)
            } else {
                return .failure(error)
            }
        }
    }

    private func promptToCreateTitleAndDescription(defaultTitle: String) -> Result<(title: String, description: String), Swift.Error> {
        let tempFile: File
        do {
            tempFile = try Env.current.file.init(write: { template(branch: defaultTitle) })
        } catch {
            return .failure(error)
        }
        defer { try? tempFile.remove() }

        guard Env.current.shell.runForegroundTask("\(Env.current.shell.editor) \(tempFile.path)") else {
            return .failure(Error.interactiveCommandFailed)
        }

        let arrays = tempFile.parse(markSwitchToSecondBlockLinePrefix: "# Description", markEndLinePrefix: nil)
        let title = arrays.firstBlock.filter { !$0.isEmpty }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let description = arrays.secondBlock.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        if title.isEmpty {
            return .failure(Error.noTitleProvided)
        } else {
            return .success((title, description))
        }
    }

    private func createDefaultTitle(from branch: String) -> String {
        let regex = NSRegularExpression("^([[:alpha:]]*?)[[:punct:]]([[:upper:]]*?[[:punct:]][[:digit:]]*?)[[:punct:]]([[:ascii:]]+)$")

        let matches = regex.matches(in: branch, options: [], range: NSRange(location: 0, length: branch.utf16.count))

        guard let match = matches.first else { return branch }

        let components = Array(1 ..< match.numberOfRanges)
            .compactMap { index -> String? in
                let range = Range(match.range(at: index), in: branch)
                return range.map { String(branch[$0]) }
            }

        return components.enumerated().reduce(into: "") { title, current in
            let (index, component) = current
            switch index {
            case 0:
                title = component.capitalized
            case 2:
                title += " \(currentIssue?.fields.summary ?? component.replacingOccurrences(of: "-", with: " "))"
            default:
                title += " \(component)"
            }
        }
    }

    private func template(branch: String) -> String {
        return """
        # Title
        \(branch)

        # Description (optional)

        """
    }
}
