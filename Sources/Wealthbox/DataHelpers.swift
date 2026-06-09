//
//  DataHelpers.swift
//  Advisor Companion
//
//  Created by David Boster on 10/22/25.
//

import Foundation

public struct DataHelpers {

    // Generic helper to decode any Decodable type from a JSON string.
    // If the decoded instance conforms to WBData, set its `json` property to the original string.
    public static func fromJSONString<T: Decodable>(_ jsonString: String, as type: T.Type) -> T {
        guard let data = jsonString.data(using: .utf8) else {
            fatalError("Failed to convert JSON string to UTF-8 Data.")
        }
        do {
            var instance = try JSONDecoder().decode(T.self, from: data)

            // If the decoded instance conforms to WBData and has a mutable `json` property,
            // set it to the original JSON string. Handle value types by copying back.
            if var wb = instance as? any WBData {
                wb.json = jsonString
                // If T is a value type that conforms to WBData, assign the mutated value back.
                if let updated = wb as? T {
                    instance = updated
                }
            }

            return instance
        } catch {
            fatalError("Failed to decode \(T.self) from JSON string: \(error)")
        }
    }
    
    public static func decode<T:Decodable>(_ jsonString: String, as type: T.Type) throws -> T {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "WealthboxDataType", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to UTF-8 Data."])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
}
