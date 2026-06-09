//
//  Event.swift
//  Advisor Companion
//
//  Created by David Boster on 10/22/25.
//

import Foundation

public struct WBEvent: WBData, Codable, Sendable {
    public var json: String?
    
   
    public let id: Int?
    public let creator: Int?
    public let createdAt: String?
    public let updatedAt: String?
    public let title: String?
    public let startsAt: String?
    public let endsAt: String?
    public let repeats: Bool?
    public let eventCategory: Int?
    public let allDay: Bool?
    public let location: String?
    public let description: String?
    public let state: String?
    public let visibleTo: String?
    public let emailInvitees: Bool?
    public let linkedTo: [WBContactLink]
    public let invitees: [WBContactLink]
    public let customFields: [WBCustomField]
    public let category: WBCategoryMember?

    private enum CodingKeys: String, CodingKey {
        case id
        case creator
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case repeats
        case eventCategory = "event_category"
        case allDay = "all_day"
        case location
        case description
        case state
        case visibleTo = "visible_to"
        case emailInvitees = "email_invitees"
        case linkedTo = "linked_to"
        case invitees
        case customFields = "custom_fields"
        case category
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBEvent {
        return DataHelpers.fromJSONString(jsonString, as: WBEvent.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBEvent {
        return try DataHelpers.decode(jsonString, as: WBEvent.self)
    }
    
    public static func sample() -> WBEvent {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
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
        """
    }
}

