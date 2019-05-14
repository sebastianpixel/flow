import AppKit

public protocol Workspace {
    func open(_ url: URL) -> Bool
    func openFile(_ fullPath: String) -> Bool
}

struct WorkspaceImpl: Workspace {
    func open(_ url: URL) -> Bool {
        return NSWorkspace.shared.open(url)
    }

    func openFile(_ fullPath: String) -> Bool {
        return NSWorkspace.shared.openFile(fullPath)
    }
}
