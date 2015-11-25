//
//  SBRegExpValidatorTests.swift
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

import XCTest

class SBRegExpValidatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPhoneNumberValidator() {
        let validator = SBRegExpValidator.phoneNumberValidator(true)
        XCTAssertNotNil(validator)
        if let validator = validator {
            XCTAssertFalse(validator.isValid(""))
            XCTAssertFalse(validator.isValid("    "))
            XCTAssertTrue(validator.isValid("+12025550129")) // US
            XCTAssertTrue(validator.isValid("12025550129")) // US
            XCTAssertTrue(validator.isValid("+1(202)5550129")) // US
            XCTAssertTrue(validator.isValid("+1-202-555-0129")) // US
            XCTAssertTrue(validator.isValid("+44 1632 960552")) // UK
            XCTAssertTrue(validator.isValid("+1-613-555-0156")) // Canada
            XCTAssertTrue(validator.isValid("+61 1900 654 321")) // Australia
        }
    }
    
    func testEmailValidator() {
        let validator = SBRegExpValidator.emailAddressValidator()
        if let validator = validator {
            XCTAssertFalse(validator.isValid(""))
            XCTAssertFalse(validator.isValid("   "))
            XCTAssertFalse(validator.isValid("someemail.com"))
            XCTAssertFalse(validator.isValid("some@email,com"))
            XCTAssertTrue(validator.isValid("some@email.com"))
            XCTAssertTrue(validator.isValid("some+1@email.com"))
        }
    }
}
