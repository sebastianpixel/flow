import Environment
import UI

public struct Reset: Procedure {
    public init() {}

    public func run() -> Bool {
        let staged = Env.current.git.stagedFiles

        guard !staged.isEmpty else {
            Env.current.shell.write("No files staged.")
            return false
        }

        let dataSource = GenericLineSelectorDataSource(items: staged)
        guard let selection = LineSelector(dataSource: dataSource)?.multiSelection() else { return true }

        return selection.output.allSatisfy(Env.current.git.reset)
    }
}
