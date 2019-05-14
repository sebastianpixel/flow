import Environment

public struct ResetLogin: Procedure {
    public init() {}

    public func run() -> Bool {
        return Env.current.login.renew(prompt: false).isSuccess
    }
}
