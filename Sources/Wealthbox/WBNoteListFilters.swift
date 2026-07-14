import Foundation

/// Documented query filters for `GET /v1/notes`.
///
/// All parameters are optional; passing none returns the first page of notes
/// visible to the authenticated user. `resourceId` + `resourceType` scope the
/// list to notes linked to a specific record (e.g. a contact/household).
/// `order` accepts the documented values `asc` (ascending by created date, the
/// default), `created` (descending by created date), and `updated` (descending
/// by updated date). `updatedSince` / `updatedBefore` are Wealthbox datetime
/// strings. `page` / `perPage` follow Wealthbox's shared pagination scheme.
public struct WBNoteListFilters: Sendable {
    public let resourceId: Int?
    public let resourceType: String?
    public let order: String?
    public let updatedSince: String?
    public let updatedBefore: String?
    public let page: Int?
    public let perPage: Int?

    public init(
        resourceId: Int? = nil,
        resourceType: String? = nil,
        order: String? = nil,
        updatedSince: String? = nil,
        updatedBefore: String? = nil,
        page: Int? = nil,
        perPage: Int? = nil
    ) {
        self.resourceId = resourceId
        self.resourceType = resourceType
        self.order = order
        self.updatedSince = updatedSince
        self.updatedBefore = updatedBefore
        self.page = page
        self.perPage = perPage
    }

    public func queryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        if let resourceId {
            items.append(URLQueryItem(name: "resource_id", value: String(resourceId)))
        }
        if let resourceType, !resourceType.isEmpty {
            items.append(URLQueryItem(name: "resource_type", value: resourceType))
        }
        if let order, !order.isEmpty {
            items.append(URLQueryItem(name: "order", value: order))
        }
        if let updatedSince, !updatedSince.isEmpty {
            items.append(URLQueryItem(name: "updated_since", value: updatedSince))
        }
        if let updatedBefore, !updatedBefore.isEmpty {
            items.append(URLQueryItem(name: "updated_before", value: updatedBefore))
        }
        if let page {
            items.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let perPage {
            items.append(URLQueryItem(name: "per_page", value: String(perPage)))
        }

        return items
    }
}
