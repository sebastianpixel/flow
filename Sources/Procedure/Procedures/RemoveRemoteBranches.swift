import Environment
import UI

public struct RemoveRemoteBranches: Procedure {
    public init() {}

    public func run() -> Bool {
        let branches = Env.current.git.branches(.all)
        guard !branches.isEmpty else {
            Env.current.shell.write("There are no remote branches to remove.")
            return false
        }

        let dataSource = GenericLineSelectorDataSource(items: branches)
        let lineSelector = LineSelector(dataSource: dataSource)

        guard let selection = lineSelector?.multiSelection()?.output, !selection.isEmpty else { return true }

        return selection.reduce(true) { result, branch in
            result && Env.current.git.deleteRemote(branch: branch)
        }
    }
}
