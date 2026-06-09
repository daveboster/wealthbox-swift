import Foundation

public struct WBPhoneNumber: WBData, Codable, Sendable {
    public var json: String?
    
    public let id: Int?
    public let address: String?
    public let principal: Bool?
    public let `extension`: String?
    public let kind: String?
    
    public static func fromJSONString(_ jsonString: String) -> WBPhoneNumber {
        return DataHelpers.fromJSONString(jsonString, as: WBPhoneNumber.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBPhoneNumber {
        return try DataHelpers.decode(jsonString, as: WBPhoneNumber.self)
    }
    
    public static func sample() -> WBPhoneNumber {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
}
}
