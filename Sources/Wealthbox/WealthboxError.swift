import Foundation

public enum WealthboxError: LocalizedError, Equatable {
    case internalError
    case network(message: String) // Transport failure (offline, DNS, timeout)
    case serverError(code: Int, message: String?)
    case badRequest(message: String) // 400 Bad Request
    case unauthorized(message: String) // 401 Unauthorized
    case rateLimited(retryAfter: Int?) // 429 Too Many Requests
    case internalServerError(message: String) // 500 Internal Server Error

    public var errorDescription: String? {
        switch self {
        case .internalError:
            return "An internal error occurred."
        case .network:
            return "A network error occurred."
        case .serverError(let code, _):
            return "The server returned an error (\(code))."
        case .badRequest:
            return "Bad Request."
        case .unauthorized:
            return "Unauthorized."
        case .rateLimited:
            return "Too Many Requests."
        case .internalServerError:
            return "Internal Server Error."
        }
    }

    public var failureReason: String? {
        switch self {
        case .internalError:
            return "The app encountered an unexpected condition."
        case .network(let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty
                ? "The request could not reach the server."
                : message
        case .serverError(_, let message):
            if let message, !message.isEmpty {
                return message
            } else {
                return "The server responded with an error status."
            }
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
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Too many requests were sent. Retry after \(retryAfter) seconds."
            } else {
                return "Too many requests were sent in a short period."
            }
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
        case .network:
            return "Check your internet connection and try again."
        case .serverError:
            return "Please try again later. If the issue persists, contact support with the error code."
        case .badRequest:
            return "Please verify the request parameters and try again."
        case .unauthorized:
            return "Please verify your credentials or re-authenticate, then try again."
        case .rateLimited:
            return "Please wait a moment and try again."
        case .internalServerError:
            return "Please try again later. If the issue persists, contact support."
        }
    }

    public var helpAnchor: String? {
        switch self {
        case .internalError:
            return "Wealthbox Help: Internal Error"
        case .network:
            return "Wealthbox Help: Network Error"
        case .serverError(let code, _):
            return "Wealthbox Help: Server Error \(code)"
        case .badRequest:
            return "Wealthbox Help: 400 Bad Request"
        case .unauthorized:
            return "Wealthbox Help: 401 Unauthorized"
        case .rateLimited:
            return "Wealthbox Help: 429 Too Many Requests"
        case .internalServerError:
            return "Wealthbox Help: 500 Internal Server Error"
        }
    }

    /// Whether a caller can reasonably retry the same request.
    ///
    /// Transport failures, rate limiting, and server-side (5xx) errors are
    /// transient and retriable; request timeouts (408) are as well. Auth,
    /// bad-request, and internal errors are not — retrying them unchanged will
    /// fail the same way.
    public var isRetriable: Bool {
        switch self {
        case .network, .rateLimited, .internalServerError:
            return true
        case .serverError(let code, _):
            return code == 408 || code >= 500
        case .internalError, .badRequest, .unauthorized:
            return false
        }
    }

    /// The server-suggested wait, in seconds, before retrying a rate-limited
    /// request, when Wealthbox supplies a `Retry-After` header.
    public var retryAfterSeconds: Int? {
        switch self {
        case .rateLimited(let retryAfter):
            return retryAfter
        default:
            return nil
        }
    }

    public static func == (lhs: WealthboxError, rhs: WealthboxError) -> Bool {
        switch (lhs, rhs) {
        case (.internalError, .internalError):
            return true
        case let (.network(lm), .network(rm)):
            return lm == rm
        case let (.serverError(lc, lm), .serverError(rc, rm)):
            return lc == rc && lm == rm
        case let (.badRequest(lm), .badRequest(rm)):
            return lm == rm
        case let (.unauthorized(lm), .unauthorized(rm)):
            return lm == rm
        case let (.rateLimited(lr), .rateLimited(rr)):
            return lr == rr
        case let (.internalServerError(lm), .internalServerError(rm)):
            return lm == rm
        default:
            return false
        }
    }
}
