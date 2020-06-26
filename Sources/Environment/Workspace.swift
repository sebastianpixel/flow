import AppKit

public protocol Workspace {
    func open(_ url: URL) -> Bool
    func openFile(_ fullPath: String) -> Bool
}

struct WorkspaceImpl: Workspace {
    func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    func openFile(_ fullPath: String) -> Bool {
        NSWorkspace.shared.openFile(fullPath)
    }
}
