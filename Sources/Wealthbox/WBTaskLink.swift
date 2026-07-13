import Foundation

/// A Wealthbox record that a task is linked to via the `linked_to` array.
///
/// The same shape is used in two directions: as an entry in the `linked_to`
/// array when creating a task (`POST /v1/tasks`), and when decoding the
/// `linked_to` array Wealthbox returns on a task.
///
/// The documented `type` values for a task link are `Contact`, `Project`, and
/// `Opportunity`. Linking to a household is done through the household's own
/// contact id with `type: "Contact"` — households, people, and organizations
/// are all contacts (mirroring `WBNoteLink`), so no separate `Household` link
/// type is required.
public struct WBTaskLink: Codable, Sendable, Hashable {
    public let id: Int
    public let type: String
    public let name: String?

    public init(id: Int, type: String, name: String? = nil) {
        self.id = id
        self.type = type
        self.name = name
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
    }
}
