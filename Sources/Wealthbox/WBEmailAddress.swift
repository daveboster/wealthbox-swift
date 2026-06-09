import Foundation

public struct WBEmailAddress: WBData, Codable, Sendable {
    public var json: String?
    
    public let id: Int?
    public let address: String?
    public let principal: Bool?
    public let kind: String?
    
    public static func fromJSONString(_ jsonString: String) -> WBEmailAddress {
        return DataHelpers.fromJSONString(jsonString, as: WBEmailAddress.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBEmailAddress {
        return try DataHelpers.decode(jsonString, as: WBEmailAddress.self)
    }
    
    public static func sample() -> WBEmailAddress {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
}
}
