import Environment
import UI

extension Git {
    func branch(containing pattern: String, excludeCurrent: Bool, options: String.CompareOptions = []) -> String? {
        let matchingBranches = branches(containing: pattern, options: options, excludeCurrent: excludeCurrent)
        switch matchingBranches.count {
        case 0:
            let branches = Env.current.git.branches(.all, excludeCurrent: excludeCurrent)
            let dataSource = GenericLineSelectorDataSource(items: branches)
            return LineSelector(dataSource: dataSource)?.singleSelection()?.output
        case 1:
            return matchingBranches.first
        default:
            let dataSource = GenericLineSelectorDataSource(items: matchingBranches)
            return LineSelector(dataSource: dataSource)?.singleSelection()?.output
        }
    }
}
