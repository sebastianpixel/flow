import Foundation

public protocol Login {
    var username: String { get }
    var password: String { get }
    func renew(prompt: Bool) -> Result<Login, Error>
}

final class LoginImpl: Login {
    lazy var username: String = {
        do {
            return try getUsername().get()
        } catch {
            Env.current.shell.write("\(error)")
            exit(EXIT_FAILURE)
        }
    }()

    lazy var password: String = {
        do {
            return try getPassword(for: username).get()
        } catch {
            Env.current.shell.write("\(error)")
            exit(EXIT_FAILURE)
        }
    }()

    func renew(prompt: Bool = true) -> Result<Login, Error> {
        if prompt, !Env.current.shell.promptDecision("Want to reset the login?") {
            exit(EXIT_SUCCESS)
        }

        return Result<Login, Error> {
            do {
                try Env.current.keychain.remove(account: username)
            } catch {
                Env.current.shell.write("Error removing login from Keychain: \(error)")
                Env.current.shell.write("Will try to create a new login.")
            }

            Env.current.defaults.removeObject(for: .username)

            let login = LoginImpl()
            _ = login.password
            return login
        }
    }

    private func getUsername() -> Result<String, Error> {
        return Result<String, Error> {
            if let username = Env.current.defaults.get(String.self, for: .username) {
                return username
            } else {
                guard let username = Env.current.shell.prompt("Enter your JIRA username"),
                    !username.isEmpty else {
                    return try renew().get().username
                }
                Env.current.defaults.set(username, for: .username)
                return username
            }
        }
    }

    private func getPassword(for username: String) -> Result<String, Error> {
        return Result<String, Error> {
            if let password = try? Env.current.keychain.load(account: username) {
                return password
            }

            let password: String
            if let pw = Env.current.shell.prompt("Enter your JIRA password", silent: true), !pw.isEmpty {
                password = pw
            } else {
                password = try renew().get().password
            }
            try Env.current.keychain.save(password: password, account: username)

            return password
        }
    }
}

struct LoginMock: Login {
    let username = "UsernameMock"

    let password = "PasswordMock"

    func renew(prompt _: Bool) -> Result<Login, Error> {
        return .success(self)
    }
}
