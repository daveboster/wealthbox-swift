import Foundation

public struct WBOccupation: WBData, Codable, Sendable {
    public var json: String?
    
    public let name: String?
    public let startDate: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case startDate = "start_date"
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBOccupation {
        return DataHelpers.fromJSONString(jsonString, as: WBOccupation.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBOccupation {
        return try DataHelpers.decode(jsonString, as: WBOccupation.self)
    }
    
    public static func sample() -> WBOccupation {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
    }
}
