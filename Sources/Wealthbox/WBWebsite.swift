import Foundation

public struct WBWebsite: WBData, Codable, Sendable {
    public var json: String?
    
    public let id: Int?
    public let address: String?
    public let principal: Bool?
    public let kind: String?
    
    public static func fromJSONString(_ jsonString: String) -> WBWebsite {
        return DataHelpers.fromJSONString(jsonString, as: WBWebsite.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBWebsite {
        return try DataHelpers.decode(jsonString, as: WBWebsite.self)
    }
    
    public static func sample() -> WBWebsite {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
    }
}
