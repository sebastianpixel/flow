import Environment

public struct RenameBranch: Procedure {
    let keepCurrentOnRemote: Bool
    let newName: String?

    public init(newName: String?, keepCurrentOnRemote: Bool) {
        self.keepCurrentOnRemote = keepCurrentOnRemote
        self.newName = newName
    }

    public func run() -> Bool {
        guard let newName = newName ?? Env.current.shell.prompt("New name") else { return false }

        let currentBranch = Env.current.git.currentBranch

        guard Env.current.git.renameCurrentBranch(newName: newName),
            Env.current.git.pushSetUpstream() else { return false }

        if !keepCurrentOnRemote, let branch = currentBranch {
            return Env.current.git.deleteRemote(branch: branch)
        }

        return true
    }
}
