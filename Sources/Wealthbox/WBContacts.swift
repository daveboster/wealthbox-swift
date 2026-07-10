//
//  WBContacts.swift
//  Advisor Companion
//
//  Created by David Boster on 10/22/25.
//

import Foundation

public struct WBContacts: WBData, Codable {
    
    public var json: String?
    public let contacts: [WBContact]
    public var page: Int?
    public var perPage: Int?
    
    public init(_ contacts: [WBContact], page: Int? = nil, perPage: Int? = nil) {
        self.contacts = contacts
        self.page = page
        self.perPage = perPage
    }
    
    private enum CodingKeys: String, CodingKey {
        case contacts
        case perPage = "per_page"
        case page
    }
    
    public static func fromJSONString(_ jsonString: String) -> WBContacts {
        return DataHelpers.fromJSONString(jsonString, as: WBContacts.self)
    }
    
    public static func decode(_ jsonString: String) throws -> WBContacts {
        return try DataHelpers.decode(jsonString, as: WBContacts.self)
    }
    
    public static func sample() -> WBContacts {
        return fromJSONString(sampleJSON())
    }
    
    public static func sampleJSON() -> String {
        return """
        {
          "contacts": [
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
          ],
          "per_page": 25,
          "page": 1
        }
        """
    }
}
