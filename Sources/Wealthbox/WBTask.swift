import Foundation

/// A Wealthbox task, as returned by `GET /v1/tasks/{id}`, the `GET /v1/tasks`
/// list, and the `POST /v1/tasks` create response.
///
/// All properties are optional (or defaulted collections) to tolerate the
/// fields Wealthbox may omit for a given task. `description` carries the task
/// body as plain text; `descriptionHtml` is the server-rendered HTML form of
/// the same content. `linkedTo` carries the records the task is attached to,
/// `customFields` carries structured custom-field values, and `subtasks`
/// carries any child tasks.
///
/// Assignment is mutually exclusive in the API: a task is assigned to a user
/// (`assignedTo`) or a team (`assignedToTeam`), not both.
public struct WBTask: WBData, Codable, Sendable, Identifiable {
    public var json: String?

    public let id: Int?
    public let creator: Int?
    public let createdAt: String?
    public let updatedAt: String?
    public let name: String?
    public let dueDate: String?
    public let complete: Bool?
    public let category: Int?
    public let priority: String?
    public let visibleTo: String?
    public let description: String?
    public let descriptionHtml: String?
    public let assignedTo: Int?
    public let assignedToTeam: Int?
    public let frame: String?
    public let repeats: Bool?
    public let completer: Int?
    public let linkedTo: [WBTaskLink]?
    public let customFields: [WBCustomField]?
    public let subtasks: [WBSubtask]?

    private enum CodingKeys: String, CodingKey {
        case id
        case creator
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case name
        case dueDate = "due_date"
        case complete
        case category
        case priority
        case visibleTo = "visible_to"
        case description
        case descriptionHtml = "description_html"
        case assignedTo = "assigned_to"
        case assignedToTeam = "assigned_to_team"
        case frame
        case repeats
        case completer
        case linkedTo = "linked_to"
        case customFields = "custom_fields"
        case subtasks
    }

    public static func fromJSONString(_ jsonString: String) -> WBTask {
        return DataHelpers.fromJSONString(jsonString, as: WBTask.self)
    }

    public static func decode(_ jsonString: String) throws -> WBTask {
        return try DataHelpers.decode(jsonString, as: WBTask.self)
    }

    public static func sample() -> WBTask {
        return fromJSONString(sampleJSON())
    }

    public static func sampleJSON() -> String {
        return """
        {
          "id": 1,
          "creator": 1,
          "created_at": "2015-05-24 10:00 AM -0400",
          "updated_at": "2015-10-12 11:30 PM -0400",
          "name": "Return Bill's call",
          "due_date": "2015-05-24 11:00 AM -0400",
          "complete": true,
          "category": 1,
          "linked_to": [
            {
              "id": 1,
              "type": "Contact",
              "name": "Kevin Anderson"
            }
          ],
          "priority": "Medium",
          "visible_to": "Everyone",
          "description": "Follow up from message...",
          "description_html": "<div>Follow up from message...</div>",
          "assigned_to": 1,
          "assigned_to_team": 10,
          "frame": "today",
          "repeats": true,
          "completer": 1,
          "custom_fields": [
            {
              "id": 1,
              "name": "My Field",
              "value": "123456789",
              "document_type": "Contact",
              "field_type": "single_select"
            }
          ],
          "subtasks": [
            {
              "id": 1,
              "creator": 1,
              "created_at": "2015-05-24 10:00 AM -0400",
              "updated_at": "2015-10-12 11:30 PM -0400",
              "due_date": "2024-10-03 12:00 PM -0400",
              "name": "Call with client",
              "complete": true,
              "priority": "None"
            }
          ]
        }
        """
    }
}
