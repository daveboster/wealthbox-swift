//
//  WBCustomField.swift
//  Advisor Companion
//
//  Created by David Boster on 10/22/25.
//

import Foundation

public struct WBCustomField: WBData, Codable, Sendable {
    public var json: String?
    public let id: Int
    public let name: String
    public let value: String
    public let documentType: String
    public let fieldType: String

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case value
        case documentType = "document_type"
        case fieldType = "field_type"
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBCustomField {
        return DataHelpers.fromJSONString(jsonString, as: WBCustomField.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBCustomField {
        return try DataHelpers.decode(jsonString, as: WBCustomField.self)
    }
    
    public static func sample() -> WBCustomField {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
        {
          "id": 1,
          "name": "My Field",
          "value": "123456789",
          "document_type": "Contact",
          "field_type": "single_select"
        }
        """
    }
}
