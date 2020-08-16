import AppKit

public protocol Workspace {
    func open(_ url: URL) -> Bool
    func openFile(_ fullPath: String) -> Bool
}

struct WorkspaceImpl: Workspace {
    func open(_ url: URL) -> Bool {
        let result = NSWorkspace.shared.open(url)
        if Env.current.debug, !result {
            Env.current.shell.write("Couldn't open URL\"\(url)\".")
        }
        return result
    }

    func openFile(_ fullPath: String) -> Bool {
        let result = NSWorkspace.shared.openFile(fullPath)
        if Env.current.debug, !result {
            Env.current.shell.write("Couldn't open path \"\(fullPath)\".")
        }
        return result
    }
}
