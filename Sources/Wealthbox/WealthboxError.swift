//
//  WealthboxError.swift
//  Advisor Companion
//
//  Created by David Boster on 10/18/25.
//

import Foundation

public enum WealthboxError: LocalizedError, Equatable {
    case internalError
    case serverError(code: Int, message: String?)
    case validationError(message: String)
    case badRequest(message: String) // 400 Bad Request
    case unauthorized(message: String) // 401 Unauthorized
    case internalServerError(message: String) // 500 Internal Server Error

    public var errorDescription: String? {
        switch self {
        case .internalError:
            return "An internal error occurred."
        case .serverError(let code, _):
            return "The server returned an error (\(code))."
        case .validationError:
            return "Validation Error."
        case .badRequest:
            return "Bad Request."
        case .unauthorized:
            return "Unauthorized."
        case .internalServerError:
            return "Internal Server Error."
        }
    }

    public var failureReason: String? {
        switch self {
        case .internalError:
            return "The app encountered an unexpected condition."
        case .serverError(_, let message):
            if let message, !message.isEmpty {
                return message
            } else {
                return "The server responded with an error status."
            }
        case .validationError(let message):
            return message
        case .badRequest(let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty
                ? "The server could not understand the request due to invalid syntax."
                : message
        case .unauthorized(let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty
                ? "Unauthorized. Access is denied due to invalid credentials."
                : message
        case .internalServerError(let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty
                ? "The server has encountered a situation it doesn't know how to handle."
                : message
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .internalError:
            return "Please try again. If the problem persists, contact support."
        case .serverError:
            return "Please try again later. If the issue persists, contact support with the error code."
        case .validationError:
            return "Please verify the command arguments and current Wealthbox data, then try again."
        case .badRequest:
            return "Please verify the request parameters and try again."
        case .unauthorized:
            return "Please verify your credentials or re-authenticate, then try again."
        case .internalServerError:
            return "Please try again later. If the issue persists, contact support."
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .internalError:
            return "Wealthbox Help: Internal Error"
        case .serverError(let code, _):
            return "Wealthbox Help: Server Error \(code)"
        case .validationError:
            return "Wealthbox Help: Validation Error"
        case .badRequest:
            return "Wealthbox Help: 400 Bad Request"
        case .unauthorized:
            return "Wealthbox Help: 401 Unauthorized"
        case .internalServerError:
            return "Wealthbox Help: 500 Internal Server Error"
        }
    }

    public static func == (lhs: WealthboxError, rhs: WealthboxError) -> Bool {
        switch (lhs, rhs) {
        case (.internalError, .internalError):
            return true
        case let (.serverError(lc, lm), .serverError(rc, rm)):
            return lc == rc && lm == rm
        case let (.validationError(lm), .validationError(rm)):
            return lm == rm
        case let (.badRequest(lm), .badRequest(rm)):
            return lm == rm
        case let (.unauthorized(lm), .unauthorized(rm)):
            return lm == rm
        case let (.internalServerError(lm), .internalServerError(rm)):
            return lm == rm
        default:
            return false
        }
    }
}
