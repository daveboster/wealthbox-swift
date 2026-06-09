// Wealthbox/WealthboxWorkspace.swift
import Foundation

public struct Workspace: WBData, Codable, Sendable {
    public let id: Int
    public let name: String
    public let firstName: String
    public let lastName: String
    public let email: String
    public let plan: String
    public let createdAt: String
    public let updatedAt: String
    public let currentUser: User?
    public let accounts: [Account]?
    public let users: [User]?
    public var json: String?
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case plan
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case currentUser = "current_user"
        case accounts
        case users
    }
    
    
    public static func fromJSONString(_ jsonString: String) -> Workspace {
        return DataHelpers.fromJSONString(jsonString, as: Workspace.self)
    }
    
    public static func decode(_ jsonString: String) throws -> Workspace {
        return try DataHelpers.decode(jsonString, as: Workspace.self)
    }
    
    public static func sample() -> Workspace {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            {
                "id": 1,
                "name": "Bill Jones",
                "first_name": "Bill",
                "last_name": "Jones",
                "email": "bill@example.com",
                "plan": "premier",
                "created_at": "2015-05-24 10:00 AM -0500",
                "updated_at": "2015-10-12 11:30 PM -0500",
                "current_user": {
                    "id": 1,
                    "email": "bill@example.com",
                    "name": "Bill Jones",
                    "account": 1
                },
                "accounts": [
                    {
                        "id": 1,
                        "name": "ABC Financial",
                        "created_at": "2015-05-24 10:00 AM -0500"
                    }
                ],
                "users": [
                    {
                        "id": 1,
                        "email": "bill@example.com",
                        "name": "Bill Jones",
                        "account": 1
                    }
                ]
            }
            """
    }
    
}
