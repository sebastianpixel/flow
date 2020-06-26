import Foundation

public protocol Defaults {
    subscript<Value: DefaultsValue>(_: DefaultsKey) -> Value? { get set }

    func get<Value: DefaultsValue>(for key: DefaultsKey) -> Value?
    func get<Value: DefaultsValue>(_ type: Value.Type, for key: DefaultsKey) -> Value?
    func set<Value: DefaultsValue>(_ value: Value, for key: DefaultsKey)

    func removeObject(for key: DefaultsKey)
}

struct DefaultsImpl: Defaults {
    subscript<Value: DefaultsValue>(key: DefaultsKey) -> Value? {
        get { get(Value.self, for: key) }
        set { newValue.map { set($0, for: key) } ?? removeObject(for: key) }
    }

    func get<Value>(for key: DefaultsKey) -> Value? where Value: DefaultsValue {
        get(Value.self, for: key)
    }

    func get<Value>(_: Value.Type, for key: DefaultsKey) -> Value? where Value: DefaultsValue {
        Value.get(for: key, from: .standard)
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
    case username, lastCommitSubject, lastCommitBody, calendarForReminders, lastPRTitle, lastPRDescription
}

public protocol DefaultsValue {
    static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Self?
}

extension Data: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Data? {
        defaults.data(forKey: key.rawValue)
    }
}

extension String: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> String? {
        defaults.string(forKey: key.rawValue)
    }
}

extension Dictionary: DefaultsValue where Key: DefaultsValue, Value: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> [Key: Value]? {
        defaults.dictionary(forKey: key.rawValue) as? [Key: Value]
    }
}

extension Array: DefaultsValue where Element: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> [Element]? {
        defaults.array(forKey: key.rawValue) as? [Element]
    }
}

extension Bool: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Bool? {
        defaults.bool(forKey: key.rawValue)
    }
}

extension Double: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Double? {
        defaults.double(forKey: key.rawValue)
    }
}

extension Float: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Float? {
        defaults.float(forKey: key.rawValue)
    }
}

extension Int: DefaultsValue {
    public static func get(for key: DefaultsKey, from defaults: UserDefaults) -> Int? {
        defaults.integer(forKey: key.rawValue)
    }
}
