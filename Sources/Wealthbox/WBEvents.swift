//
//  WBEvents.swift
//  Advisor Companion
//
//  Created by David Boster on 10/22/25.
//

import Foundation

public struct WBEvents: WBData, Codable, Sendable {
    public var json: String?
    
    public let events: [WBEvent]
    
    public init(_ events: [WBEvent]) {
        self.events = events
    }
    
    private enum CodingKeys: String, CodingKey {
        case events
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBEvents {
        return DataHelpers.fromJSONString(jsonString, as: WBEvents.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBEvents {
        return try DataHelpers.decode(jsonString, as: WBEvents.self)
    }
    
    public static func sample() -> WBEvents {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
        {
          "events": [
            {
              "id": 1,
              "creator": 1,
              "created_at": "2015-05-24 10:00 AM -0400",
              "updated_at": "2015-10-12 11:30 PM -0400",
              "title": "Client Meeting",
              "starts_at": "2015-05-24 10:00 AM -0400",
              "ends_at": "2015-05-24 11:00 AM -0400",
              "repeats": true,
              "event_category": 2,
              "all_day": true,
              "location": "Conference Room",
              "description": "Review meeting for Kevin...",
              "state": "confirmed",
              "visible_to": "Everyone",
              "email_invitees": true,
              "linked_to": [
                {
                  "id": 1,
                  "type": "Contact",
                  "name": "Kevin Anderson"
                }
              ],
              "invitees": [
                {
                  "id": 1,
                  "type": "Contact",
                  "name": "Kevin Anderson"
                }
              ],
              "custom_fields": [
                {
                  "id": 1,
                  "name": "My Field",
                  "value": "123456789",
                  "document_type": "Contact",
                  "field_type": "single_select"
                }
              ]
            }
          ]
        }
        """
    }
}
