import Foundation

public struct WBCategoryMember: Codable, Sendable, Identifiable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct WBEventCategories: WBData, Codable, Sendable {
    public var json: String?
    public let eventCategories: [WBCategoryMember]

    public init(_ eventCategories: [WBCategoryMember]) {
        self.eventCategories = eventCategories
    }

    private enum CodingKeys: String, CodingKey {
        case eventCategories = "event_categories"
        case tags
        case categories
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let eventCategories = try container.decodeIfPresent([WBCategoryMember].self, forKey: .eventCategories) {
            self.eventCategories = eventCategories
        } else if let tags = try container.decodeIfPresent([WBCategoryMember].self, forKey: .tags) {
            self.eventCategories = tags
        } else if let categories = try container.decodeIfPresent([WBCategoryMember].self, forKey: .categories) {
            self.eventCategories = categories
        } else {
            self.eventCategories = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventCategories, forKey: .eventCategories)
    }

    public static func fromJSONString(_ jsonString: String) -> WBEventCategories {
        DataHelpers.fromJSONString(jsonString, as: WBEventCategories.self)
    }

    public static func decode(_ jsonString: String) throws -> WBEventCategories {
        try DataHelpers.decode(jsonString, as: WBEventCategories.self)
    }

    public static func sample() -> WBEventCategories {
        fromJSONString(sampleJSON())
    }

    public static func sampleJSON() -> String {
        """
        {
          "event_categories": [
            {
              "id": 1,
              "name": "Client Meeting"
            },
            {
              "id": 2,
              "name": "Review"
            }
          ]
        }
        """
    }
}
