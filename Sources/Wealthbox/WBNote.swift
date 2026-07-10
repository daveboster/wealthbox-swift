import Foundation

/// A Wealthbox note, as returned by `GET /v1/notes/{id}` and by the
/// `POST /v1/notes` create response.
///
/// All properties are optional to tolerate the fields Wealthbox may omit for a
/// given note. `content` carries the note body; `linkedTo` carries the records
/// the note is attached to.
public struct WBNote: WBData, Codable, Sendable, Identifiable {
    public let id: Int?
    public let creator: Int?
    public let createdAt: String?
    public let updatedAt: String?
    public let content: String?
    public let visibleTo: String?
    public let linkedTo: [WBNoteLink]?
    public let tags: [WBTag]?
    public var json: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case creator
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case content
        case visibleTo = "visible_to"
        case linkedTo = "linked_to"
        case tags
    }

    public static func fromJSONString(_ jsonString: String) -> WBNote {
        return DataHelpers.fromJSONString(jsonString, as: WBNote.self)
    }

    public static func decode(_ jsonString: String) throws -> WBNote {
        return try DataHelpers.decode(jsonString, as: WBNote.self)
    }

    public static func sample() -> WBNote {
        return fromJSONString(sampleJSON())
    }

    public static func sampleJSON() -> String {
        return """
        {
          "id": 1,
          "creator": 1,
          "created_at": "2015-05-24 10:00 AM -0400",
          "updated_at": "2015-05-24 10:00 AM -0400",
          "content": "Spoke with Kevin about the upcoming review meeting.",
          "visible_to": "Everyone",
          "linked_to": [
            {
              "id": 1,
              "type": "Contact",
              "name": "Kevin Anderson"
            }
          ],
          "tags": [
            {
              "id": 1,
              "name": "Meeting"
            }
          ]
        }
        """
    }
}
