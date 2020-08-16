@testable import Environment

extension Env {
    static let mock = Env(
        toolName: current.toolName,
        debug: current.debug,
        jira: JiraImpl(),
        shell: ShellMock(),
        git: GitMock(),
        defaults: DefaultsImpl(),
        keychain: KeychainImpl(),
        login: LoginMock(),
        directory: DirectoryImpl.self,
        file: FileImpl.self,
        urlSession: URLSessionMock(),
        workspace: WorkspaceImpl()
    )
}
