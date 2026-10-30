import Foundation

/// Safe, serializable, type-erased dynamic arguments extracted for an intent proposal.
public struct IntentArguments: Codable, Sendable, Equatable {
    public var storage: [String: String]

    public init(storage: [String: String] = [:]) {
        self.storage = storage
    }

    public subscript(key: String) -> String? {
        get { storage[key] }
        set { storage[key] = newValue }
    }

    public func string(for key: String) -> String? {
        storage[key]
    }

    public func int(for key: String) -> Int? {
        guard let val = storage[key] else { return nil }
        return Int(val)
    }

    public func double(for key: String) -> Double? {
        guard let val = storage[key] else { return nil }
        return Double(val)
    }

    public func bool(for key: String) -> Bool? {
        guard let val = storage[key] else { return nil }
        let lower = val.lowercased()
        if lower == "true" || lower == "1" { return true }
        if lower == "false" || lower == "0" { return false }
        return nil
    }

    /// Attempts to decode the stored arguments into a strongly-typed `Decodable` struct.
    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let jsonMap = storage.mapValues { val -> Any in
            let lower = val.lowercased()
            if lower == "true" { return true }
            if lower == "false" { return false }
            if let i = Int(val) { return i }
            if let d = Double(val) { return d }
            return val
        }
        let data = try JSONSerialization.data(withJSONObject: jsonMap)
        return try JSONDecoder().decode(type, from: data)
    }
}
