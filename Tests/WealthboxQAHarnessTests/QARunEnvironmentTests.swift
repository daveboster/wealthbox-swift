import Foundation
import Testing
@testable import WealthboxQA

struct QARunEnvironmentTests {
    @Test
    func emptyEnvironmentIsNotConfigured() {
        let environment = QARunEnvironment(environment: [:])

        #expect(!environment.isConfigured)
        #expect(environment.accessToken == nil)
        #expect(environment.expectedWorkspaceID == nil)
        #expect(environment.expectedWorkspaceName == "QA")
        #expect(!environment.allowMultiWorkspaceUser)
        #expect(environment.seedHouseholdName == "Sample Household")
    }

    @Test
    func whitespaceOnlyTokenDoesNotConfigureARun() {
        let environment = QARunEnvironment(environment: [
            "WEALTHBOX_QA_ACCESS_TOKEN": "   "
        ])

        #expect(!environment.isConfigured)
    }

    @Test
    func populatedEnvironmentParsesEveryVariable() {
        let environment = QARunEnvironment(environment: [
            "WEALTHBOX_QA_ACCESS_TOKEN": "token-xyz",
            "WEALTHBOX_QA_WORKSPACE_ID": "125001",
            "WEALTHBOX_QA_WORKSPACE_NAME": "QA Sandbox",
            "WEALTHBOX_QA_ALLOW_MULTI_WORKSPACE_USER": "true",
            "WEALTHBOX_QA_BASE_URL": "https://example.com",
            "WEALTHBOX_QA_SEED_HOUSEHOLD": "Demo Household"
        ])

        #expect(environment.isConfigured)
        #expect(environment.accessToken == "token-xyz")
        #expect(environment.expectedWorkspaceID == 125_001)
        #expect(environment.expectedWorkspaceName == "QA Sandbox")
        #expect(environment.allowMultiWorkspaceUser)
        #expect(environment.baseURL == "https://example.com")
        #expect(environment.seedHouseholdName == "Demo Household")
    }

    @Test
    func nonNumericWorkspaceIDParsesAsMissing() {
        let environment = QARunEnvironment(environment: [
            "WEALTHBOX_QA_ACCESS_TOKEN": "token",
            "WEALTHBOX_QA_WORKSPACE_ID": "QA"
        ])

        #expect(environment.expectedWorkspaceID == nil)
    }

    @Test
    func multiWorkspaceOverrideRequiresATruthyValue() {
        for (value, expected) in [("1", true), ("TRUE", true), ("yes", true), ("0", false), ("off", false), ("", false)] {
            let environment = QARunEnvironment(environment: [
                "WEALTHBOX_QA_ALLOW_MULTI_WORKSPACE_USER": value
            ])
            #expect(environment.allowMultiWorkspaceUser == expected, "value: \(value)")
        }
    }

    @Test
    func makeClientUsesConfiguredBaseURL() {
        let environment = QARunEnvironment(
            accessToken: "token",
            expectedWorkspaceID: 125_001,
            baseURL: "https://example.com"
        )

        #expect(environment.makeClient().currentBaseUrl == "https://example.com")
    }
}
