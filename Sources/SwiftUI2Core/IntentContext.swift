import Foundation

/// Bounded, serializable application context snapshot provided to the model.
public struct IntentContext: Codable, Sendable, Equatable {
    public let revision: UInt64
    public let timestamp: Date
    public let localeIdentifier: String
    public let timeZoneIdentifier: String
    public let payload: [String: String]

    public init(
        revision: UInt64 = 1,
        timestamp: Date = Date(),
        localeIdentifier: String = Locale.current.identifier,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        payload: [String: String] = [:]
    ) {
        self.revision = revision
        self.timestamp = timestamp
        self.localeIdentifier = localeIdentifier
        self.timeZoneIdentifier = timeZoneIdentifier
        self.payload = payload
    }

    public static let empty = IntentContext(revision: 0)
}
