import Foundation

public protocol Defaults {
    func get<Value: DefaultsValue>(for key: DefaultsKey) -> Value?
    func get<Value: DefaultsValue>(_ type: Value.Type, for key: DefaultsKey) -> Value?
    func set<Value: DefaultsValue>(_ value: Value, for key: DefaultsKey)
    func removeObject(for key: DefaultsKey)
}

struct DefaultsImpl: Defaults {
    func get<Value>(for key: DefaultsKey) -> Value? where Value: DefaultsValue {
        return get(Value.self, for: key)
    }

    func get<Value>(_: Value.Type, for key: DefaultsKey) -> Value? where Value: DefaultsValue {
        return Value.get(for: key, from: .standard)
    }

    func set<Value: DefaultsValue>(_ value: Value, for key: DefaultsKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }

    func removeObject(for key: DefaultsKey) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }
}

public enum DefaultsKey: String {
    case username, lastCommitSubject, lastCommitBody
}

public protocol DefaultsValue {
    static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Self?
}

extension Data: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Data? {
        return defaults.data(forKey: key.rawValue)
    }
}

extension String: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> String? {
        return defaults.string(forKey: key.rawValue)
    }
}

extension Dictionary: DefaultsValue where Key: DefaultsValue, Value: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> [Key: Value]? {
        return defaults.dictionary(forKey: key.rawValue) as? [Key: Value]
    }
}

extension Array: DefaultsValue where Element: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> [Element]? {
        return defaults.array(forKey: key.rawValue) as? [Element]
    }
}

extension Bool: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Bool? {
        return defaults.bool(forKey: key.rawValue)
    }
}

extension Double: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Double? {
        return defaults.double(forKey: key.rawValue)
    }
}

extension Float: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Float? {
        return defaults.float(forKey: key.rawValue)
    }
}

extension Int: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Int? {
        return defaults.integer(forKey: key.rawValue)
    }
}
