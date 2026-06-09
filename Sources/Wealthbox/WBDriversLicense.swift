import Foundation

public struct WBDriversLicense: WBData, Codable, Sendable {
    public var json: String?
    public let number: String?
    public let state: String?
    public let issuedDate: String?
    public let expiresDate: String?
    
    private enum CodingKeys: String, CodingKey {
        case number
        case state
        case issuedDate = "issued_date"
        case expiresDate = "expires_date"
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBDriversLicense {
        return DataHelpers.fromJSONString(jsonString, as: WBDriversLicense.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBDriversLicense {
        return try DataHelpers.decode(jsonString, as: WBDriversLicense.self)
    }
    
    public static func sample() -> WBDriversLicense {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
}
}
