import Foundation

/// A unique identifier for one QA-workspace run, carried on every
/// artifact that run creates so the sweep can find (and only ever touch)
/// test-created data.
///
/// Format: `yyyyMMdd-HHmmss-xxxx` — a UTC timestamp plus a four-character
/// random suffix, e.g. `20260714-153012-k4d9`. The format is strict so marker
/// parsing cannot mistake ordinary text for a run id.
public struct QARunID: Sendable, Equatable, Hashable, CustomStringConvertible {
    public let rawValue: String

    public var description: String { rawValue }

    /// Creates a run id from an existing raw value, validating the format.
    public init?(rawValue: String) {
        guard Self.isValid(rawValue) else {
            return nil
        }
        self.rawValue = rawValue
    }

    /// Generates a new run id. `date` and `suffix` are injectable for
    /// deterministic tests.
    public static func generate(date: Date = Date(), suffix: String? = nil) -> QARunID {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd-HHmmss"

        let stamp = formatter.string(from: date)
        let randomPart = suffix ?? Self.randomSuffix()
        guard let id = QARunID(rawValue: "\(stamp)-\(randomPart)") else {
            // Only reachable with an invalid injected suffix; regenerate
            // randomly rather than trap in a test-support path.
            return generate(date: date, suffix: nil)
        }
        return id
    }

    public static func isValid(_ rawValue: String) -> Bool {
        rawValue.wholeMatch(of: /\d{8}-\d{6}-[a-z0-9]{4}/) != nil
    }

    private static func randomSuffix() -> String {
        let alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<4).compactMap { _ in alphabet.randomElement() })
    }
}
