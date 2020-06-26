import Environment

public struct ResetLogin: Procedure {
    public init() {}

    public func run() -> Bool {
        Env.current.login.renew(prompt: false).isSuccess
    }
}
