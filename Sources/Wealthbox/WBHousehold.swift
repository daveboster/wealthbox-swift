import Foundation

public struct WBHousehold: WBData, Codable, Sendable {
    public var json: String?
    
    public let name: String?
    public let title: String?
    public let id: Int?
    public let members: [WBHouseholdMember]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case members
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBHousehold {
        return DataHelpers.fromJSONString(jsonString, as: WBHousehold.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBHousehold {
        return try DataHelpers.decode(jsonString, as: WBHousehold.self)
    }
    
    public static func sample() -> WBHousehold {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
}
}
