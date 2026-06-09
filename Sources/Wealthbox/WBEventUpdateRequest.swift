import Foundation

public struct WBEventUpdateRequest: Encodable, Sendable {
    public let title: String
    public let startsAt: String
    public let endsAt: String
    public let eventCategory: Int

    private enum CodingKeys: String, CodingKey {
        case title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case eventCategory = "event_category"
    }

    init(event: WBEvent, eventCategory: Int) throws {
        guard let title = event.title, !title.isEmpty else {
            throw WealthboxError.validationError(message: "Event \(event.id ?? 0) is missing title. No update sent.")
        }
        guard let startsAt = event.startsAt, !startsAt.isEmpty else {
            throw WealthboxError.validationError(message: "Event \(event.id ?? 0) is missing starts_at. No update sent.")
        }
        guard let endsAt = event.endsAt, !endsAt.isEmpty else {
            throw WealthboxError.validationError(message: "Event \(event.id ?? 0) is missing ends_at. No update sent.")
        }

        self.title = title
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.eventCategory = eventCategory
    }
}
