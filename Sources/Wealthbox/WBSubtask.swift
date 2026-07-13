import Foundation

/// A child task nested under a parent task's `subtasks` array, as returned by
/// the Wealthbox tasks endpoints.
///
/// All properties are optional to tolerate fields Wealthbox may omit for a
/// given subtask.
public struct WBSubtask: WBData, Codable, Sendable, Identifiable {
    public var json: String?

    public let id: Int?
    public let creator: Int?
    public let createdAt: String?
    public let updatedAt: String?
    public let name: String?
    public let dueDate: String?
    public let complete: Bool?
    public let priority: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case creator
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case name
        case dueDate = "due_date"
        case complete
        case priority
    }

    public static func fromJSONString(_ jsonString: String) -> WBSubtask {
        return DataHelpers.fromJSONString(jsonString, as: WBSubtask.self)
    }

    public static func decode(_ jsonString: String) throws -> WBSubtask {
        return try DataHelpers.decode(jsonString, as: WBSubtask.self)
    }

    public static func sample() -> WBSubtask {
        return fromJSONString(sampleJSON())
    }

    public static func sampleJSON() -> String {
        return """
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
        """
    }
}
