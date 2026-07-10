import Foundation

public struct WBCustomFieldOption: Codable, Sendable, Identifiable {
    public let id: Int
    public let label: String
}

public struct WBCustomFieldDefinition: Codable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let documentType: String
    public let fieldType: String
    public let options: [WBCustomFieldOption]?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case documentType = "document_type"
        case fieldType = "field_type"
        case options
    }
}

public struct WBCustomFieldDefinitions: WBData, Codable, Sendable {
    public var json: String?
    public let customFields: [WBCustomFieldDefinition]

    public init(_ customFields: [WBCustomFieldDefinition]) {
        self.json = nil
        self.customFields = customFields
    }

    private enum CodingKeys: String, CodingKey {
        case customFields = "custom_fields"
    }

    public static func fromJSONString(_ jsonString: String) -> WBCustomFieldDefinitions {
        DataHelpers.fromJSONString(jsonString, as: WBCustomFieldDefinitions.self)
    }

    public static func decode(_ jsonString: String) throws -> WBCustomFieldDefinitions {
        try DataHelpers.decode(jsonString, as: WBCustomFieldDefinitions.self)
    }

    public static func sample() -> WBCustomFieldDefinitions {
        fromJSONString(sampleJSON())
    }

    public static func sampleJSON() -> String {
        """
        {
          "custom_fields": [
            {
              "id": 1,
              "name": "Meeting Type",
              "document_type": "Event",
              "field_type": "single_select",
              "options": [
                {
                  "id": 10,
                  "label": "Annual Review"
                }
              ]
            }
          ]
        }
        """
    }
}
