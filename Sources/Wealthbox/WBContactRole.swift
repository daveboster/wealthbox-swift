import Foundation

public struct WBContactRole: WBData, Codable, Sendable {
    public var json: String?
    
    public let id: Int?
    public let name: String?
    public let value: Int?
    public let assignedTo: WBAssignedTo?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case value
        case assignedTo = "assigned_to"
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBContactRole {
        return DataHelpers.fromJSONString(jsonString, as: WBContactRole.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBContactRole {
        return try DataHelpers.decode(jsonString, as: WBContactRole.self)
    }
    
    public static func sample() -> WBContactRole {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
}
}
