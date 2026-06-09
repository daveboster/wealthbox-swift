//
//  WBContactLink.swift
//  Advisor Companion
//
//  Created by David Boster on 10/22/25.
//

import Foundation

public struct WBContactLink: WBData, Codable, Sendable {
    public var json: String?
    
    public let id: Int
    public let type: String
    public let name: String
    
    public static func fromJSONString(_ jsonString: String) -> WBContactLink {
        return DataHelpers.fromJSONString(jsonString, as: WBContactLink.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBContactLink {
        return try DataHelpers.decode(jsonString, as: WBContactLink.self)
    }
    
    public static func sample() -> WBContactLink {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
        {
          "id": 1,
          "type": "Contact",
          "name": "Kevin Anderson"
        }
        """
    }
}
