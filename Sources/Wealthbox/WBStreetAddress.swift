import Foundation

public struct WBStreetAddress: WBData, Codable, Sendable {
    public var json: String?
    
    public let streetLine1: String?
    public let streetLine2: String?
    public let city: String?
    public let state: String?
    public let zipCode: String?
    public let country: String?
    public let principal: Bool?
    public let kind: String?
    public let id: Int?
    public let address: String?
    
    private enum CodingKeys: String, CodingKey {
        case streetLine1 = "street_line_1"
        case streetLine2 = "street_line_2"
        case city
        case state
        case zipCode = "zip_code"
        case country
        case principal
        case kind
        case id
        case address
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBStreetAddress {
        return DataHelpers.fromJSONString(jsonString, as: WBStreetAddress.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBStreetAddress {
        return try DataHelpers.decode(jsonString, as: WBStreetAddress.self)
    }
    
    public static func sample() -> WBStreetAddress {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
}
}
