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
}
