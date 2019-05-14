import Environment

public struct XCOpen: Procedure {
    public init() {}

    public func run() -> Bool {
        guard let files = Env.current.shell.run("ls `pwd`")?.components(separatedBy: .newlines) else { return false }

        let relevantFileEndings = ["xcworkspace", "xcodeproj", "playground"]

        for ending in relevantFileEndings {
            if let file = files.first(where: { $0.hasSuffix(ending) }) {
                return Env.current.workspace.openFile(file)
            }
        }

        Env.current.shell.write("No file found ending with \(relevantFileEndings.joined(separator: ", ")).")

        return false
    }
}
