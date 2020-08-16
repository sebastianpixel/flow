import Environment
import Foundation
import Request

public struct OpenCurrentSprint: Procedure {
    enum Error: Swift.Error {
        case noCurrentSprint
    }

    private let jiraProject: String?

    public init(jiraProject: String?) {
        self.jiraProject = jiraProject
    }

    public func run() -> Bool {
        guard let jiraProject = getJiraProject(from: jiraProject) else { return false }

        return GetCurrentSprint(jiraProject: jiraProject)
            .request()
            .await()
            .flatMap { response -> Result<Bool, Swift.Error> in
                guard let currentSprint = response.sprints.first,
                    let url = URL(string: currentSprint.viewBoardsUrl)
                    else {
                        return .failure(Error.noCurrentSprint)
                }
                return .success(Env.current.workspace.open(url))
            }
            .mapError { error -> Swift.Error in
                if case let ApiClientError.status(_, bitbucketError?) = error {
                    Env.current.shell.write(bitbucketError.message)
                }
                if Env.current.debug {
                    Env.current.shell.write("\(error)")
                }
                return error
            }
            .isSuccess
    }
}
