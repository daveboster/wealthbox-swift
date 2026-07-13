import Foundation

/// Documented query filters for `GET /v1/tasks`.
///
/// All parameters are optional; passing none returns the first page of tasks.
/// `resourceId` + `resourceType` scope the list to tasks linked to a specific
/// record (e.g. a contact/household), which — together with `completed` and
/// `updatedSince` — is the polling shape used to read task status back, since
/// Wealthbox exposes no task webhooks.
///
/// `updatedSince` / `updatedBefore` are Wealthbox datetime strings; `taskType`
/// accepts `all`, `parents`, or `subtasks`.
public struct WBTaskListFilters: Sendable {
    public let resourceId: Int?
    public let resourceType: String?
    public let assignedTo: Int?
    public let assignedToTeam: Int?
    public let createdBy: Int?
    public let completed: Bool?
    public let taskType: String?
    public let updatedSince: String?
    public let updatedBefore: String?
    public let page: Int?
    public let perPage: Int?

    public init(
        resourceId: Int? = nil,
        resourceType: String? = nil,
        assignedTo: Int? = nil,
        assignedToTeam: Int? = nil,
        createdBy: Int? = nil,
        completed: Bool? = nil,
        taskType: String? = nil,
        updatedSince: String? = nil,
        updatedBefore: String? = nil,
        page: Int? = nil,
        perPage: Int? = nil
    ) {
        self.resourceId = resourceId
        self.resourceType = resourceType
        self.assignedTo = assignedTo
        self.assignedToTeam = assignedToTeam
        self.createdBy = createdBy
        self.completed = completed
        self.taskType = taskType
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
        if let assignedTo {
            items.append(URLQueryItem(name: "assigned_to", value: String(assignedTo)))
        }
        if let assignedToTeam {
            items.append(URLQueryItem(name: "assigned_to_team", value: String(assignedToTeam)))
        }
        if let createdBy {
            items.append(URLQueryItem(name: "created_by", value: String(createdBy)))
        }
        if let completed {
            items.append(URLQueryItem(name: "completed", value: completed ? "true" : "false"))
        }
        if let taskType, !taskType.isEmpty {
            items.append(URLQueryItem(name: "task_type", value: taskType))
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
