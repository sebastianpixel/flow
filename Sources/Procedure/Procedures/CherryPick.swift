import Environment
import Foundation
import UI

public struct CherryPick: Procedure {
    public init() {}

    public func run() -> Bool {
        guard let currentBranch = Env.current.git.currentBranch else {
            Env.current.shell.write("No current branch.")
            return false
        }
        let branches = Env.current.git.branches(.unmerged)
        let branchesDataSource = GenericLineSelectorDataSource(items: branches)
        let branchesLineSelector = LineSelector(dataSource: branchesDataSource)
        guard let selectedBranch = branchesLineSelector?.singleSelection()?.output else {
            return true
        }

        let additionsInB = Env.current.git.difference(of: currentBranch, to: selectedBranch).additionsInB

        guard !additionsInB.isEmpty else {
            Env.current.shell.write("No commits in \(selectedBranch) that are not already in current branch (\(currentBranch).")
            return true
        }

        let commitsDataSource = GenericLineSelectorDataSource(items: additionsInB, line: \.subject)
        let commitsLineSelector = LineSelector(dataSource: commitsDataSource)
        guard let commit = commitsLineSelector?.singleSelection()?.output else {
            return true
        }
        return Env.current.git.cherryPick(commit)
    }
}
