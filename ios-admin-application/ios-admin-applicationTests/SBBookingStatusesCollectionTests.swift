//
//  SBBookingStatusesCollectionTests.swift
//  ios-admin-application
//
//  Created by Michail Grebionkin on 13.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

import XCTest

class SBBookingStatusesCollectionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBookingCollection() {
        let data = [
            [
                "color" : "0ea0cc",
                "description" : "<null>",
                "id" : "3",
                "is_default" : "1",
                "name" : "Approved"
            ],
            [
                "color" : "48ff00",
                "description" : "<null>",
                "id" : "4",
                "is_default" : "0",
                "name" : "status2"
            ]
        ]
        let statusesCollection = SBBookingStatusesCollection(statusesList: data)
        XCTAssertNotNil(statusesCollection)
        XCTAssertNotNil(statusesCollection.defaultStatus)
        XCTAssertTrue(statusesCollection.count() > 0)
        XCTAssertTrue(statusesCollection.count() == UInt(data.count))
        XCTAssertNotNil(statusesCollection[0])
        XCTAssertNotNil(statusesCollection["3"])
        if let isDefault = statusesCollection["3"]?.isDefault {
            XCTAssertTrue(isDefault)
        }
        XCTAssertNotNil(statusesCollection["4"])
        if let isDefault = statusesCollection["4"]?.isDefault {
            XCTAssertFalse(isDefault)
        }
    }
}
