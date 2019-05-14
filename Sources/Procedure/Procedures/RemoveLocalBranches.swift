import Environment
import UI

public struct RemoveLocalBranches: Procedure {
    public init() {}

    public func run() -> Bool {
        let mergedPrefix = "[MERGED] "
        let unmergedPrefix = "[UNMERGED] "
        let merged = Env.current.git.branches(.merged).map { "\(mergedPrefix)\($0)" }
        let unmerged = Env.current.git.branches(.unmerged).map { "\(unmergedPrefix)\($0)" }
        let items = merged + unmerged

        guard !items.isEmpty else {
            Env.current.shell.write("There are no local branches to remove.")
            return false
        }

        let dataSource = GenericLineSelectorDataSource(items: items)
        let lineSelector = LineSelector(dataSource: dataSource)

        guard let selection = lineSelector?.multiSelection()?.output, !selection.isEmpty else { return true }

        return selection.reduce(true) { result, branch in
            let branchToDelete = branch.replacingOccurrences(of: branch.contains(unmergedPrefix) ? unmergedPrefix : mergedPrefix, with: "")
            return result && Env.current.git.deleteLocal(branch: branchToDelete, forced: true)
        }
    }
}
