import Environment

public struct ResolveConflicts: Procedure {
    public init() {}

    public func run() -> Bool {
        let conflictedFiles = Env.current.git.conflictedFiles
        guard !conflictedFiles.isEmpty else {
            Env.current.shell.write("No files with conflicts found.")
            return false
        }

        return Env.current.shell.runForegroundTask("vim -p \(conflictedFiles.joined(separator: " "))")
    }
}
