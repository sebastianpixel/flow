import Environment

public struct Push: Procedure {
    public init() {}

    public func run() -> Bool {
        return Env.current.git.push()
    }
}
