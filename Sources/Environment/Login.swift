import Foundation

public protocol Login {
    var username: String { get }
    var password: String { get }

    func renew(prompt: Bool) -> Result<Login, Error>
}

final class LoginImpl: Login {
    enum Error: Swift.Error {
        case optOut
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
        Result<String, Swift.Error> {
            if let username = Env.current.defaults[.username] as String? {
                return username
            } else {
                guard let username = Env.current.shell.prompt("Enter your JIRA username"),
                    !username.isEmpty
                    else {
                        return try renew(prompt: false).get().username
                }
                Env.current.defaults[.username] = username
                return username
            }
        }
    }

    private func getPassword(for username: String) -> Result<String, Swift.Error> {
        let password = Env.current.keychain.read(account: username)

        switch password {
        case let .success(success?):
            return .success(success)
        case let .failure(failure):
            if Env.current.debug {
                Env.current.shell.write("\(failure)")
            }
        default:
            break
        }

        if let newPassword = Env.current.shell.prompt("Enter your JIRA password", newline: false, silent: true), !newPassword.isEmpty {
            return Env.current.keychain.create(password: newPassword, account: username)
                .map { _ in newPassword }
                .flatMapError { _ in renew(prompt: true).map(\.password) }
        }

        return renew(prompt: true).map(\.password)
    }
}
