import Foundation
import Testing
@testable import Wealthbox

struct EventWeekFilterTests {
    @Test
    func sundayStartWeekRangeUsesOffsetFromReferenceWeek() throws {
        let reference = try Date.fromTestISO8601("2026-06-09T16:00:00Z")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let currentWeek = try WealthboxWeekRange(weekOffset: 0, referenceDate: reference, calendar: calendar)
        let previousWeek = try WealthboxWeekRange(weekOffset: -1, referenceDate: reference, calendar: calendar)
        let nextWeek = try WealthboxWeekRange(weekOffset: 1, referenceDate: reference, calendar: calendar)
        let expectedCurrentStart = try Date.fromTestISO8601("2026-06-07T00:00:00Z")
        let expectedCurrentEnd = try Date.fromTestISO8601("2026-06-14T00:00:00Z")
        let expectedPreviousStart = try Date.fromTestISO8601("2026-05-31T00:00:00Z")
        let expectedNextEnd = try Date.fromTestISO8601("2026-06-21T00:00:00Z")

        #expect(currentWeek.start == expectedCurrentStart)
        #expect(currentWeek.end == expectedCurrentEnd)
        #expect(previousWeek.start == expectedPreviousStart)
        #expect(previousWeek.end == currentWeek.start)
        #expect(nextWeek.start == currentWeek.end)
        #expect(nextWeek.end == expectedNextEnd)
    }

    @Test
    func eventsFilteredByWeekIncludeStartAndExcludeNextSunday() throws {
        let reference = try Date.fromTestISO8601("2026-06-09T16:00:00Z")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let events = try WBEvents.decode(
            """
            {
              "events": [
                {
                  "id": 1,
                  "creator": 1,
                  "created_at": "2026-06-01 10:00 AM +0000",
                  "updated_at": "2026-06-01 10:00 AM +0000",
                  "title": "Previous week",
                  "starts_at": "2026-06-06 11:59 PM +0000",
                  "ends_at": "2026-06-07 12:30 AM +0000",
                  "linked_to": [],
                  "invitees": [],
                  "custom_fields": []
                },
                {
                  "id": 2,
                  "creator": 1,
                  "created_at": "2026-06-07 10:00 AM +0000",
                  "updated_at": "2026-06-07 10:00 AM +0000",
                  "title": "Week start",
                  "starts_at": "2026-06-07 12:00 AM +0000",
                  "ends_at": "2026-06-07 12:30 AM +0000",
                  "linked_to": [],
                  "invitees": [],
                  "custom_fields": []
                },
                {
                  "id": 3,
                  "creator": 1,
                  "created_at": "2026-06-10 10:00 AM +0000",
                  "updated_at": "2026-06-10 10:00 AM +0000",
                  "title": "Mid week",
                  "starts_at": "2026-06-10 09:00 AM +0000",
                  "ends_at": "2026-06-10 10:00 AM +0000",
                  "linked_to": [],
                  "invitees": [],
                  "custom_fields": []
                },
                {
                  "id": 4,
                  "creator": 1,
                  "created_at": "2026-06-14 10:00 AM +0000",
                  "updated_at": "2026-06-14 10:00 AM +0000",
                  "title": "Next week",
                  "starts_at": "2026-06-14 12:00 AM +0000",
                  "ends_at": "2026-06-14 12:30 AM +0000",
                  "linked_to": [],
                  "invitees": [],
                  "custom_fields": []
                }
              ]
            }
            """
        )

        let filtered = try events.filteredByWeek(offset: 0, referenceDate: reference, calendar: calendar)

        #expect(filtered.events.map { $0.id } == [2, 3])
    }
}

private extension Date {
    static func fromTestISO8601(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: value) else {
            throw TestDateError.invalid(value)
        }
        return date
    }
}

private enum TestDateError: Error {
    case invalid(String)
}
