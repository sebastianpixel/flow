import Foundation
import Security

public protocol Keychain {
    func create(password: String, account: String) -> Result<Void, Swift.Error>
    func read(account: String) -> Result<String?, Swift.Error>
    func update(password: String, account: String) -> Result<Void, Swift.Error>
    func delete(account: String) -> Result<Void, Swift.Error>
}

struct KeychainImpl: Keychain {
    struct Error: Swift.Error {
        let message: String

        init(message: String) {
            self.message = message
        }

        init(status: OSStatus, account: String) {
            switch status {
            case errSecItemNotFound:
                message = "Password for \"\(account)\" was not found."
            case errSecIO:
                message = "IO went bad. Account: \(account)."
            default:
                message = SecCopyErrorMessageString(status, nil) as String? ?? "Status: \(status)" + ". Account: \(account)"
            }
        }
    }

    func create(password: String, account: String) -> Result<Void, Swift.Error> {
        data(from: password).flatMap { data in
            let query: NSDictionary = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: Env.current.toolName,
                kSecAttrAccount: account,
                kSecValueData: data
            ]

            let status = SecItemAdd(query, nil)

            guard status == errSecSuccess else {
                return .failure(Error(status: status, account: account))
            }

            return .success(())
        }
    }

    func read(account: String) -> Result<String?, Swift.Error> {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Env.current.toolName,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var ref: CFTypeRef?

        let status = SecItemCopyMatching(query, &ref)

        guard status == errSecSuccess else {
            return .failure(Error(status: status, account: account))
        }

        return .success((ref as? Data).flatMap { String(data: $0, encoding: .utf8) })
    }

    func update(password: String, account: String) -> Result<Void, Swift.Error> {
        data(from: password).flatMap { data in
            let query: NSDictionary = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: Env.current.toolName,
                kSecAttrAccount: account
            ]

            let status = SecItemUpdate(query, [kSecValueData: data] as NSDictionary)

            guard status == errSecSuccess else {
                return .failure(Error(status: status, account: account))
            }

            return .success(())
        }
    }

    func delete(account: String) -> Result<Void, Swift.Error> {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Env.current.toolName,
            kSecAttrAccount: account,
            kSecReturnData: true
        ]

        let status = SecItemDelete(query)

        guard status == errSecSuccess else {
            return .failure(Error(status: status, account: account))
        }

        return .success(())
    }

    private func data(from string: String) -> Result<Data, Swift.Error> {
        if let data = string.data(using: .utf8, allowLossyConversion: false) {
            return .success(data)
        } else {
            return .failure(Error(message: "Could not transform \(string) to data."))
        }
    }
}
