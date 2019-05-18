import Foundation

public protocol Login {
    var username: String { get }
    var password: String { get }

    func renew(prompt: Bool) -> Result<Login, Error>
}

final class LoginImpl: Login {
    enum Error: Swift.Error {
        case optOut, noPassword
    }

    lazy var username: String = {
        switch getUsername() {
        case let .success(success):
            return success
        case let .failure(failure):
            Env.current.shell.write("\(failure)")
            exit(EXIT_FAILURE)
        }
    }()

    lazy var password: String = {
        switch getPassword(for: username) {
        case let .success(success):
            return success
        case let .failure(failure):
            Env.current.shell.write("\(failure)")
            exit(EXIT_FAILURE)
        }
    }()

    func renew(prompt: Bool = true) -> Result<Login, Swift.Error> {
        if prompt, !Env.current.shell.promptDecision("Want to reset the login?") {
            return .failure(Error.optOut)
        }

        switch Env.current.keychain.delete(account: username) {
        case let .failure(failure):
            Env.current.shell.write("Error removing login from Keychain: \(failure)")
            Env.current.shell.write("Will try to create a new login.")
        default:
            break
        }

        Env.current.defaults.removeObject(for: .username)

        let login = LoginImpl()
        _ = login.password
        return .success(login)
    }

    private func getUsername() -> Result<String, Swift.Error> {
        return Result<String, Swift.Error> {
            if let username = Env.current.defaults[.username] as String? {
                return username
            } else {
                guard let username = Env.current.shell.prompt("Enter your JIRA username", newline: false, silent: false),
                    !username.isEmpty else {
                    return try renew().get().username
                }
                Env.current.defaults[.username] = username
                return username
            }
        }
    }

    private func getPassword(for username: String) -> Result<String, Swift.Error> {
        return Env.current.keychain.read(account: username)
            .flatMapError { _ -> Result<String?, Swift.Error> in
                let password = Env.current.shell.prompt("Enter your JIRA password", newline: false, silent: true)
                if password?.isEmpty ?? true {
                    return renew().map { $0.password }
                } else {
                    return .success(password)
                }
            }
            .flatMap { password -> Result<(String, Void), Swift.Error> in
                guard let password = password else { return .failure(Error.noPassword) }
                return Env.current.keychain.create(password: password, account: username).map { (password, $0) }
            }
            .map { $0.0 }
    }
}
