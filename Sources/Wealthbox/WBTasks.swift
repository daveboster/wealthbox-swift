import Foundation

/// The list envelope returned by `GET /v1/tasks`: a `tasks` array of `WBTask`.
///
/// Wealthbox uses a page-based pagination scheme (`page` / `per_page`) across
/// its list endpoints, returned as top-level fields alongside the collection
/// (mirroring `WBContacts`). Both are optional so a response that omits them
/// still decodes.
public struct WBTasks: WBData, Codable, Sendable {
    public var json: String?

    public let tasks: [WBTask]
    public var page: Int?
    public var perPage: Int?

    public init(_ tasks: [WBTask], page: Int? = nil, perPage: Int? = nil) {
        self.tasks = tasks
        self.page = page
        self.perPage = perPage
    }

    private enum CodingKeys: String, CodingKey {
        case tasks
        case perPage = "per_page"
        case page
    }

    public static func fromJSONString(_ jsonString: String) -> WBTasks {
        return DataHelpers.fromJSONString(jsonString, as: WBTasks.self)
    }

    public static func decode(_ jsonString: String) throws -> WBTasks {
        return try DataHelpers.decode(jsonString, as: WBTasks.self)
    }

    public static func sample() -> WBTasks {
        return fromJSONString(sampleJSON())
    }

    public static func sampleJSON() -> String {
        return """
        {
          "tasks": [
        \(WBTask.sampleJSON())
          ],
          "per_page": 25,
          "page": 1
        }
        """
    }
}
