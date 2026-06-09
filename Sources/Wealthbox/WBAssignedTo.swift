import Foundation

public struct WBAssignedTo: WBData, Codable, Sendable {
    public var json: String?
    
    public let id: Int?
    public let type: String?
    public let name: String?
    
    public static func fromJSONString(_ jsonString: String) -> WBAssignedTo {
        return DataHelpers.fromJSONString(jsonString, as: WBAssignedTo.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBAssignedTo {
        return try DataHelpers.decode(jsonString, as: WBAssignedTo.self)
    }
    
    public static func sample() -> WBAssignedTo {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
            """
    }
}
