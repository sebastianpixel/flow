import Foundation

public struct Env {
    public static var current = Env()

    public var toolName = ""
    public var debug = false
    public var jira: Jira = JiraImpl()
    public var shell: Shell = ShellImpl()
    public var git: Git = GitImpl()
    public var defaults: Defaults = DefaultsImpl()
    public var keychain: Keychain = KeychainImpl()
    public var login: Login = LoginImpl()
    public var directory: Directory.Type = DirectoryImpl.self
    public var file: File.Type = FileImpl.self
    public var urlSession: URLSessionProtocol = URLSession.shared
    public var workspace: Workspace = WorkspaceImpl()
    public var clipboard: Clipboard = ClipboardImpl()
}
