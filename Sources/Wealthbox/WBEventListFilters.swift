import Foundation

public struct WBEventListFilters: Sendable {
    public let fromDate: String?
    public let untilDate: String?

    public init(fromDate: String? = nil, untilDate: String? = nil) {
        self.fromDate = fromDate
        self.untilDate = untilDate
    }

    public func queryItems() throws -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        if let fromDate, !fromDate.isEmpty {
            items.append(URLQueryItem(name: "start_date_min", value: try Self.validatedDate(fromDate, label: "from")))
        }
        if let untilDate, !untilDate.isEmpty {
            items.append(URLQueryItem(name: "start_date_max", value: try Self.validatedDate(untilDate, label: "until")))
        }

        return items
    }

    private static func validatedDate(_ value: String, label: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.split(separator: "-", omittingEmptySubsequences: false)
        guard components.count == 3,
              components[0].count == 4,
              components[1].count == 2,
              components[2].count == 2,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            throw invalidDate(value, label: label)
        }

        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar(identifier: .gregorian)
        dateComponents.timeZone = TimeZone(secondsFromGMT: 0)
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day

        guard let date = dateComponents.date,
              dateComponents.calendar?.component(.year, from: date) == year,
              dateComponents.calendar?.component(.month, from: date) == month,
              dateComponents.calendar?.component(.day, from: date) == day else {
            throw invalidDate(value, label: label)
        }

        return trimmed
    }

    private static func invalidDate(_ value: String, label: String) -> WealthboxError {
        .validationError(message: "Invalid \(label) date '\(value)'. Use YYYY-MM-DD format.")
    }
}
