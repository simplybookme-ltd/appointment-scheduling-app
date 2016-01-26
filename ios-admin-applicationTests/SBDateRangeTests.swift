//
//  SBDateRangeTests.swift
//  ios-admin-application
//
//  Created by Michail Grebionkin on 12.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

import XCTest

class SBDateRangeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testContainsDate() {
        let today = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = NSDateComponents()
        dateComponents.day = 5
        let biggerDate = calendar.dateByAddingComponents(dateComponents, toDate: today, options: NSCalendarOptions(rawValue: 0))
        XCTAssertNotNil(biggerDate)
        dateComponents.day = -5
        let lowerDate = calendar.dateByAddingComponents(dateComponents, toDate: today, options: NSCalendarOptions(rawValue: 0))
        XCTAssertNotNil(lowerDate)
        
        var range = SBDateRange(start: lowerDate, end: biggerDate)
        XCTAssertNotNil(range)
        XCTAssertTrue(range!.containsDate(today))
        XCTAssertFalse(range!.containsDate(calendar.dateByAddingComponents(dateComponents, toDate: range!.start!, options: NSCalendarOptions(rawValue: 0))!))
        
        range = SBDateRange(start: nil, end: biggerDate)
        XCTAssertNotNil(range)
        XCTAssertTrue(range!.containsDate(today))
        dateComponents.day = 10
        XCTAssertFalse(range!.containsDate(calendar.dateByAddingComponents(dateComponents, toDate: range!.end!, options: NSCalendarOptions(rawValue: 0))!))
        
        range = SBDateRange(start: lowerDate, end: nil)
        XCTAssertNotNil(range)
        XCTAssertTrue(range!.containsDate(today))
        dateComponents.day = -10
        XCTAssertFalse(range!.containsDate(calendar.dateByAddingComponents(dateComponents, toDate: range!.start!, options: NSCalendarOptions(rawValue: 0))!))
    }
}
