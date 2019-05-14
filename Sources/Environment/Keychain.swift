import Foundation
import Security

public protocol Keychain {
    func save(password: String, account: String) throws
    func load(account: String) throws -> String?
    func update(password: String, account: String) throws
    func remove(account: String) throws
}

struct KeychainImpl: Keychain {
    struct Error: Swift.Error {
        let action: Action
        let error: String

        enum Action: String {
            case read, update, remove, write, retrieve
        }
    }

    func update(password: String, account: String) throws {
        guard let dataFromString = password.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return }
        let keychainQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Env.current.toolName,
            kSecAttrAccount: account
        ] as CFDictionary

        let status = SecItemUpdate(keychainQuery, [kSecValueData: dataFromString] as CFDictionary)

        if status != errSecSuccess,
            let error = SecCopyErrorMessageString(status, nil) {
            throw Error(action: .read, error: error as String)
        }
    }

    func remove(account: String) throws {
        let keychainQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Env.current.toolName,
            kSecAttrAccount: account,
            kSecReturnData: kCFBooleanTrue!
        ] as CFDictionary

        let status = SecItemDelete(keychainQuery)

        if status != errSecSuccess,
            let error = SecCopyErrorMessageString(status, nil) {
            throw Error(action: .remove, error: error as String)
        }
    }

    func save(password: String, account: String) throws {
        guard let dataFromString = password.data(using: String.Encoding.utf8,
                                                 allowLossyConversion: false) else { return }

        let keychainQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Env.current.toolName,
            kSecAttrAccount: account,
            kSecValueData: dataFromString
        ] as CFDictionary

        let status = SecItemAdd(keychainQuery, nil)

        if status != errSecSuccess,
            let error = SecCopyErrorMessageString(status, nil) {
            throw Error(action: .write, error: error as String)
        }
    }

    func load(account: String) throws -> String? {
        // Instantiate a new default keychain query
        // Tell the query to return a result
        // Limit our results to one item
        let keychainQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Env.current.toolName,
            kSecAttrAccount: account,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary

        var dataTypeRef: CFTypeRef?

        let status = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        var contentsOfKeychain: String?

        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                contentsOfKeychain = String(data: retrievedData, encoding: .utf8)
            }
        } else if let error = SecCopyErrorMessageString(status, nil) {
            throw Error(action: .retrieve, error: error as String)
        }

        return contentsOfKeychain
    }
}
