import Foundation

public struct WealthboxWeekRange: Equatable, Sendable {
    public let start: Date
    public let end: Date

    public init(
        weekOffset: Int,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) throws {
        var sundayCalendar = calendar
        sundayCalendar.firstWeekday = 1

        guard let referenceWeek = sundayCalendar.dateInterval(of: .weekOfYear, for: referenceDate),
              let shiftedStart = sundayCalendar.date(byAdding: .weekOfYear, value: weekOffset, to: referenceWeek.start),
              let shiftedEnd = sundayCalendar.date(byAdding: .day, value: 7, to: shiftedStart) else {
            throw WealthboxWeekRangeError.unableToBuildRange
        }

        self.start = shiftedStart
        self.end = shiftedEnd
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}

public enum WealthboxWeekRangeError: Error, Equatable {
    case unableToBuildRange
}

public extension WBEvents {
    func filteredByWeek(
        offset: Int,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) throws -> WBEvents {
        let weekRange = try WealthboxWeekRange(
            weekOffset: offset,
            referenceDate: referenceDate,
            calendar: calendar
        )
        return WBEvents(events.filter { event in
            guard let startsAt = event.startsAt,
                  let startsAtDate = WealthboxEventDateParser.date(from: startsAt) else {
                return false
            }
            return weekRange.contains(startsAtDate)
        })
    }
}

enum WealthboxEventDateParser {
    static func date(from value: String) -> Date? {
        if let date = makeWealthboxDateFormatter().date(from: value) {
            return date
        }
        return ISO8601DateFormatter().date(from: value)
    }

    private static func makeWealthboxDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd hh:mm a Z"
        return formatter
    }
}
