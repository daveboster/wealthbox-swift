import Foundation

/// Encodable request body for `POST /v1/tasks`.
///
/// `name` and `dueDate` are the only required fields; every other field is
/// optional and, because Swift's synthesized `Encodable` uses
/// `encodeIfPresent` for optionals, `nil` values are omitted from the encoded
/// JSON rather than sent as `null` (matching `WBNoteCreateRequest`).
///
/// `dueDate` is a Wealthbox datetime string, e.g. `"2015-05-24 11:00 AM -0400"`.
/// Assignment is mutually exclusive: set `assignedTo` (user id) or
/// `assignedToTeam` (team id), not both.
public struct WBTaskCreateRequest: Encodable, Sendable {
    public let name: String
    public let dueDate: String
    public let complete: Bool?
    public let category: Int?
    public let priority: String?
    public let visibleTo: String?
    public let description: String?
    public let assignedTo: Int?
    public let assignedToTeam: Int?
    public let linkedTo: [WBTaskLink]?
    public let customFields: [WBCustomFieldRequest]?
    public let subtasks: [WBSubtaskRequest]?

    public init(
        name: String,
        dueDate: String,
        complete: Bool? = nil,
        category: Int? = nil,
        priority: String? = nil,
        visibleTo: String? = nil,
        description: String? = nil,
        assignedTo: Int? = nil,
        assignedToTeam: Int? = nil,
        linkedTo: [WBTaskLink]? = nil,
        customFields: [WBCustomFieldRequest]? = nil,
        subtasks: [WBSubtaskRequest]? = nil
    ) {
        self.name = name
        self.dueDate = dueDate
        self.complete = complete
        self.category = category
        self.priority = priority
        self.visibleTo = visibleTo
        self.description = description
        self.assignedTo = assignedTo
        self.assignedToTeam = assignedToTeam
        self.linkedTo = linkedTo
        self.customFields = customFields
        self.subtasks = subtasks
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case dueDate = "due_date"
        case complete
        case category
        case priority
        case visibleTo = "visible_to"
        case description
        case assignedTo = "assigned_to"
        case assignedToTeam = "assigned_to_team"
        case linkedTo = "linked_to"
        case customFields = "custom_fields"
        case subtasks
    }
}

/// A custom-field value supplied when creating or updating a task.
///
/// The write shape is only `{ id, value }` — unlike the read shape
/// (`WBCustomField`), which also carries `name`, `document_type`, and
/// `field_type`. Percentage fields take their natural value (submit `"75"` for
/// 75%, not `"0.75"`).
public struct WBCustomFieldRequest: Encodable, Sendable {
    public let id: Int
    public let value: String

    public init(id: Int, value: String) {
        self.id = id
        self.value = value
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case value
    }
}

/// A child task supplied inside a `POST /v1/tasks` request's `subtasks` array.
///
/// `dueLater` is the documented interval string describing when the subtask is
/// due relative to the start of the parent task; supply it in place of an
/// absolute `dueDate` when the subtask should be scheduled off the parent.
public struct WBSubtaskRequest: Encodable, Sendable {
    public let name: String
    public let dueDate: String?
    public let priority: String?
    public let dueLater: String?

    public init(
        name: String,
        dueDate: String? = nil,
        priority: String? = nil,
        dueLater: String? = nil
    ) {
        self.name = name
        self.dueDate = dueDate
        self.priority = priority
        self.dueLater = dueLater
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case dueDate = "due_date"
        case priority
        case dueLater = "due_later"
    }
}
