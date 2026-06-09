import Foundation

public struct WBTag: WBData, Codable, Sendable {
    public var json: String?
    
    public let id: Int?
    public let name: String?
    
    public static func fromJSONString(_ jsonString: String) -> WBTag {
        return DataHelpers.fromJSONString(jsonString, as: WBTag.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBTag {
        return try DataHelpers.decode(jsonString, as: WBTag.self)
    }
    
    public static func sample() -> WBTag {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
}
    
}
