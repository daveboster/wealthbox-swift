import Testing
@testable import Wealthbox

struct WealthboxErrorTests {
    @Test
    func retriableErrorsAreClassified() {
        #expect(WealthboxError.network(message: "offline").isRetriable)
        #expect(WealthboxError.rateLimited(retryAfter: 5).isRetriable)
        #expect(WealthboxError.internalServerError(message: "").isRetriable)
        #expect(WealthboxError.serverError(code: 503, message: nil).isRetriable)
        #expect(WealthboxError.serverError(code: 408, message: nil).isRetriable)
    }

    @Test
    func nonRetriableErrorsAreClassified() {
        #expect(!WealthboxError.unauthorized(message: "").isRetriable)
        #expect(!WealthboxError.badRequest(message: "").isRetriable)
        #expect(!WealthboxError.internalError.isRetriable)
        #expect(!WealthboxError.serverError(code: 404, message: nil).isRetriable)
    }

    @Test
    func retryAfterSecondsIsOnlyPresentForRateLimited() {
        #expect(WealthboxError.rateLimited(retryAfter: 12).retryAfterSeconds == 12)
        #expect(WealthboxError.rateLimited(retryAfter: nil).retryAfterSeconds == nil)
        #expect(WealthboxError.network(message: "x").retryAfterSeconds == nil)
    }

    @Test
    func localizedDescriptionsNeverLeakSecrets() {
        // Error copy is user-facing; make sure the new cases carry sensible text.
        #expect(WealthboxError.rateLimited(retryAfter: 30).errorDescription == "Too Many Requests.")
        #expect(WealthboxError.network(message: "offline").errorDescription == "A network error occurred.")
    }

    @Test
    func failureReasonDoesNotEchoRawServerResponseBody() {
        // Server response bodies can contain client PII; they must not surface
        // through the user-facing/loggable LocalizedError text.
        let sensitive = "passport_number=AB1234CD contact=Jane Doe"
        #expect(WealthboxError.badRequest(message: sensitive).failureReason?.contains(sensitive) != true)
        #expect(WealthboxError.unauthorized(message: sensitive).failureReason?.contains(sensitive) != true)
        #expect(WealthboxError.internalServerError(message: sensitive).failureReason?.contains(sensitive) != true)
        #expect(WealthboxError.serverError(code: 422, message: sensitive).failureReason?.contains(sensitive) != true)
        // The raw message stays available on the associated value for
        // deliberate, non-user-facing use.
        if case let .badRequest(message) = WealthboxError.badRequest(message: sensitive) {
            #expect(message == sensitive)
        } else {
            Issue.record("Expected .badRequest to retain its associated message.")
        }
    }
}
