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
    }

    private func data(from string: String) -> Result<Data, Swift.Error> {
        if let data = string.data(using: .utf8, allowLossyConversion: false) {
            return .success(data)
        } else {
            return .failure(Error(message: "Could not transform \(string) to data."))
        }
    }

    func create(password: String, account: String) -> Result<Void, Swift.Error> {
        return data(from: password).flatMap { data in
            let query: NSDictionary = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: Env.current.toolName,
                kSecAttrAccount: account,
                kSecValueData: data
            ]

            let status = SecItemAdd(query, nil)

            if status != errSecSuccess,
                let error = SecCopyErrorMessageString(status, nil) {
                return .failure(Error(message: error as String))
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

        return Result<String?, Swift.Error> {
            if status != errSecSuccess,
                let error = SecCopyErrorMessageString(status, nil) {
                throw Error(message: error as String)
            }

            return (ref as? Data).flatMap { String(data: $0, encoding: .utf8) }
        }
    }

    func update(password: String, account: String) -> Result<Void, Swift.Error> {
        return data(from: password).flatMap { data in
            let query: NSDictionary = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: Env.current.toolName,
                kSecAttrAccount: account
            ]

            let status = SecItemUpdate(query, [kSecValueData: data] as NSDictionary)

            if status != errSecSuccess,
                let error = SecCopyErrorMessageString(status, nil) {
                return .failure(Error(message: error as String))
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

        if status != errSecSuccess,
            let error = SecCopyErrorMessageString(status, nil) {
            return .failure(Error(message: error as String))
        }
        return .success(())
    }
}
