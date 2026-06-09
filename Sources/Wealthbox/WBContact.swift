//
//  WBBase.swift
//  Advisor Companion
//
//  Created by David Boster on 10/22/25.
//
import Foundation

public struct WBContact: WBData, Codable, Sendable, Identifiable {
    public let id: Int?
    public let creator: Int?
    public let createdAt: String?
    public let updatedAt: String?
    public let prefix: String?
    public let name: String?
    public let firstName: String?
    public let middleName: String?
    public let lastName: String?
    public let suffix: String?
    public let nickname: String?
    public let jobTitle: String?
    public let twitterName: String?
    public let linkedinURL: String?
    public let backgroundInformation: String?
    public let birthDate: String?
    public let anniversary: String?
    public let clientSince: String?
    public let dateOfDeath: String?
    public let assignedTo: Int?
    public let referredBy: Int?
    public let type: String?
    public let gender: String?
    public let contactSource: String?
    public let contactType: String?
    public let status: String?
    public let maritalStatus: String?
    public let attorney: Int?
    public let cpa: Int?
    public let doctor: Int?
    public let insurance: Int?
    public let businessManager: Int?
    public let familyOfficer: Int?
    public let assistant: Int?
    public let other: Int?
    public let trustedContact: Int?
    public let importantInformation: String?
    public let personalInterests: String?
    public let investmentObjective: String?
    public let timeHorizon: String?
    public let riskTolerance: String?
    public let mutualFundExperience: Int?
    public let stocksAndBondsExperience: Int?
    public let partnershipsExperience: Int?
    public let otherInvestingExperience: Int?
    public let grossAnnualIncome: Int?
    public let assets: Int?
    public let nonLiquidAssets: Int?
    public let liabilities: Int?
    public let adjustedGrossIncome: Int?
    public let estimatedTaxes: Int?
    public let confirmedByTaxReturn: Bool?
    public let taxYear: Int?
    public let taxBracket: Int?
    public let birthPlace: String?
    public let maidenName: String?
    public let passportNumber: String?
    public let greenCardNumber: String?
    public let occupation: WBOccupation?
    public let driversLicense: WBDriversLicense?
    public let retirementDate: String?
    public let signedFeeAgreementDate: String?
    public let signedIpsAgreementDate: String?
    public let signedFpAgreementDate: String?
    public let lastAdvOfferingDate: String?
    public let initialCrsOfferingDate: String?
    public let lastCrsOfferingDate: String?
    public let lastPrivacyOfferingDate: String?
    public let companyName: String?
    public let household: WBHousehold?
    public let image: String?
    public let tags: [WBTag]?
    public let streetAddresses: [WBStreetAddress]?
    public let emailAddresses: [WBEmailAddress]?
    public let phoneNumbers: [WBPhoneNumber]?
    public let websites: [WBWebsite]?
    public let customFields: [WBCustomField]?
    public let contactRoles: [WBContactRole]?
    public let externalUniqueId: String?
    public var json: String?
    
    public let members: [WBHouseholdMember]?

    private enum CodingKeys: String, CodingKey {
        case id
        case creator
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case prefix
        case name
        case firstName = "first_name"
        case middleName = "middle_name"
        case lastName = "last_name"
        case suffix
        case nickname
        case jobTitle = "job_title"
        case twitterName = "twitter_name"
        case linkedinURL = "linkedin_url"
        case backgroundInformation = "background_information"
        case birthDate = "birth_date"
        case anniversary
        case clientSince = "client_since"
        case dateOfDeath = "date_of_death"
        case assignedTo = "assigned_to"
        case referredBy = "referred_by"
        case type
        case gender
        case contactSource = "contact_source"
        case contactType = "contact_type"
        case status
        case maritalStatus = "marital_status"
        case attorney
        case cpa
        case doctor
        case insurance
        case businessManager = "business_manager"
        case familyOfficer = "family_officer"
        case assistant
        case other
        case trustedContact = "trusted_contact"
        case importantInformation = "important_information"
        case personalInterests = "personal_interests"
        case investmentObjective = "investment_objective"
        case timeHorizon = "time_horizon"
        case riskTolerance = "risk_tolerance"
        case mutualFundExperience = "mutual_fund_experience"
        case stocksAndBondsExperience = "stocks_and_bonds_experience"
        case partnershipsExperience = "partnerships_experience"
        case otherInvestingExperience = "other_investing_experience"
        case grossAnnualIncome = "gross_annual_income"
        case assets
        case nonLiquidAssets = "non_liquid_assets"
        case liabilities
        case adjustedGrossIncome = "adjusted_gross_income"
        case estimatedTaxes = "estimated_taxes"
        case confirmedByTaxReturn = "confirmed_by_tax_return"
        case taxYear = "tax_year"
        case taxBracket = "tax_bracket"
        case birthPlace = "birth_place"
        case maidenName = "maiden_name"
        case passportNumber = "passport_number"
        case greenCardNumber = "green_card_number"
        case occupation
        case driversLicense = "drivers_license"
        case retirementDate = "retirement_date"
        case signedFeeAgreementDate = "signed_fee_agreement_date"
        case signedIpsAgreementDate = "signed_ips_agreement_date"
        case signedFpAgreementDate = "signed_fp_agreement_date"
        case lastAdvOfferingDate = "last_adv_offering_date"
        case initialCrsOfferingDate = "initial_crs_offering_date"
        case lastCrsOfferingDate = "last_crs_offering_date"
        case lastPrivacyOfferingDate = "last_privacy_offering_date"
        case companyName = "company_name"
        case household
        case image
        case tags
        case streetAddresses = "street_addresses"
        case emailAddresses = "email_addresses"
        case phoneNumbers = "phone_numbers"
        case websites
        case customFields = "custom_fields"
        case contactRoles = "contact_roles"
        case externalUniqueId = "external_unique_id"
        case members
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBContact {
        return DataHelpers.fromJSONString(jsonString, as: WBContact.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBContact {
        return try DataHelpers.decode(jsonString, as: WBContact.self)
    }
    
    public static func sample() -> WBContact {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
        {
          "id": 1,
          "creator": 1,
          "created_at": "2015-05-24 10:00 AM -0400",
          "updated_at": "2015-10-12 11:30 PM -0400",
          "prefix": "Mr.",
          "first_name": "Kevin",
          "middle_name": "James",
          "last_name": "Anderson",
          "suffix": "M.D.",
          "nickname": "Kev",
          "job_title": "CEO",
          "twitter_name": "kev.anderson",
          "linkedin_url": "linkedin.com/in/kanderson",
          "background_information": "Met Kevin at a conference.",
          "birth_date": "1975-10-27",
          "anniversary": "1998-11-29",
          "client_since": "2002-05-21",
          "date_of_death": "2018-01-21",
          "assigned_to": 1,
          "referred_by": 1,
          "type": "Person",
          "gender": "Male",
          "contact_source": "Referral",
          "contact_type": "Client",
          "status": "Active",
          "marital_status": "Married",
          "attorney": 1,
          "cpa": 1,
          "doctor": 1,
          "insurance": 1,
          "business_manager": 1,
          "family_officer": 1,
          "assistant": 1,
          "other": 1,
          "trusted_contact": 1,
          "important_information": "Has 3 kids in college",
          "personal_interests": "Skiing: Downhill, Traveling",
          "investment_objective": "Income",
          "time_horizon": "Intermediate",
          "risk_tolerance": "Moderate",
          "mutual_fund_experience": 3,
          "stocks_and_bonds_experience": 2,
          "partnerships_experience": 1,
          "other_investing_experience": 5,
          "gross_annual_income": 100000,
          "assets": 250000,
          "non_liquid_assets": 50000,
          "liabilities": 50000,
          "adjusted_gross_income": 75000,
          "estimated_taxes": 18000,
          "confirmed_by_tax_return": true,
          "tax_year": 2015,
          "tax_bracket": 10,
          "birth_place": "New York, NY",
          "maiden_name": "Anderson",
          "passport_number": "AB1234CD5689",
          "green_card_number": "ZX567HG134",
          "occupation": {
            "name": "CEO",
            "start_date": "2015-11-25"
          },
          "drivers_license": {
            "number": "1111111",
            "state": "New York",
            "issued_date": "2001-10-27",
            "expires_date": "2011-10-27"
          },
          "retirement_date": "2025-09-30",
          "signed_fee_agreement_date": "2013-05-15",
          "signed_ips_agreement_date": "2014-03-12",
          "signed_fp_agreement_date": "2015-03-12",
          "last_adv_offering_date": "2013-09-21",
          "initial_crs_offering_date": "2012-09-21",
          "last_crs_offering_date": "2013-09-21",
          "last_privacy_offering_date": "2011-10-23",
          "company_name": "Acme Co.",
          "household": {
            "name": "The Andersons",
            "title": "Head",
            "id": 0,
            "members": [
              {
                "id": 1,
                "first_name": "Kevin",
                "last_name": "Anderson",
                "title": "Head",
                "type": "Person"
              }
            ]
          },
          "image": "https://app.crmworkspace.com/avatar.png",
          "tags": [
            {
              "id": 1,
              "name": "Clients"
            }
          ],
          "street_addresses": [
            {
              "street_line_1": "155 12th Ave.",
              "street_line_2": "Apt 3B",
              "city": "New York",
              "state": "New York",
              "zip_code": "10001",
              "country": "United States",
              "principal": true,
              "kind": "Work",
              "id": 1,
              "address": "155 12th Ave., Apt 3B, New York, New York 10001, United States"
            }
          ],
          "email_addresses": [
            {
              "id": 1,
              "address": "kevin.anderson@example.com",
              "principal": true,
              "kind": "Work"
            }
          ],
          "phone_numbers": [
            {
              "id": 1,
              "address": "(555) 555-5555",
              "principal": true,
              "extension": "77",
              "kind": "Work"
            }
          ],
          "websites": [
            {
              "id": 1,
              "address": "https://www.example.com",
              "principal": true,
              "kind": "Website"
            }
          ],
          "custom_fields": [
            {
              "id": 1,
              "name": "My Field",
              "value": "123456789",
              "document_type": "Contact",
              "field_type": "single_select"
            }
          ],
          "contact_roles": [
            {
              "id": 1,
              "name": "Planning Advisor",
              "value": 1,
              "assigned_to": {
                "id": 1,
                "type": "User",
                "name": "Kevin Anderson"
              }
            }
          ],
          "external_unique_id": null
        }
        """
    }
}
