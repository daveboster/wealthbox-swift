import Foundation

public struct WBHouseholdMember: WBData, Codable, Sendable {
    public var json: String?
    
    public let id: Int?
    public let firstName: String?
    public let lastName: String?
    public let title: String?
    public let type: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case title
        case type
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBHouseholdMember {
        return DataHelpers.fromJSONString(jsonString, as: WBHouseholdMember.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBHouseholdMember {
        return try DataHelpers.decode(jsonString, as: WBHouseholdMember.self)
    }
    
    public static func sample() -> WBHouseholdMember {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
}
}
