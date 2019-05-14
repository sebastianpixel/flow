import Environment

public struct PrintUsageDescription: Procedure {
    private let usageDescription: String
    private let showInPager: Bool

    public init(usageDescription: String, showInPager: Bool) {
        self.usageDescription = usageDescription
        self.showInPager = showInPager
    }

    public func run() -> Bool {
        let pager = showInPager ? " | ${PAGER:-less}" : ""
        return Env.current.shell.runForegroundTask("echo \"\(usageDescription)\"\(pager)")
    }
}
