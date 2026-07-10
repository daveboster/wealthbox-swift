import Foundation

/// A Wealthbox record that a note is linked to, such as a contact or household.
///
/// The same shape is used in two directions: as an entry in the `linked_to`
/// array when creating a note (`POST /v1/notes`), and when decoding the
/// `linked_to` array Wealthbox returns on a note.
public struct WBNoteLink: Codable, Sendable, Hashable {
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
