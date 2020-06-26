import Environment

public struct Push: Procedure {
    public init() {}

    public func run() -> Bool {
        Env.current.git.push()
    }
}
