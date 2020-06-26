import Environment
import UI

public struct Revert: Procedure {
    public init() {}

    public func run() -> Bool {
        let log = Env.current.git.log
        guard !log.isEmpty else {
            Env.current.shell.write("Git log is empty.")
            return true
        }
        let dataSource = GenericLineSelectorDataSource(items: log, line: \.subject)
        let lineSelector = LineSelector(dataSource: dataSource)
        guard let selectedCommit = lineSelector?.singleSelection()?.output else {
            return true
        }
        return Env.current.git.revert(selectedCommit)
    }
}
