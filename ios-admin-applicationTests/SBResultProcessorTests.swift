//
//  SBResultProcessorTests.swift
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.142.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

import XCTest

class SBResultProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNumberResultProcessor() {
        let processor = SBNumberProcessor()
        XCTAssertTrue(processor.process("42.0"))
        XCTAssertTrue(processor.process("42."))
        XCTAssertTrue(processor.process("42.42"))
        XCTAssertTrue(processor.process(".42"))
        XCTAssertTrue(processor.process("42"))
        XCTAssertTrue(processor.process("  42 "))
        XCTAssertFalse(processor.process(".42s"))
        XCTAssertFalse(processor.process("42s"))
        XCTAssertFalse(processor.process("a.42s"))
        XCTAssertFalse(processor.process("42s"))
        XCTAssertFalse(processor.process(" 42s"))
        XCTAssertTrue(processor.process(NSNumber(double: 42.0)))
        XCTAssertTrue(processor.process(NSNumber(int: 42)))
    }
    
    func testClassCheckProcessor() {
        let processor = SBClassCheckProcessor(expectedClass: NSArray.classForCoder())
        if let check = processor! as SBClassCheckProcessor! {
            XCTAssertTrue(check.process(["", ""]))
            XCTAssertTrue(check.process(NSMutableArray()))
            XCTAssertFalse(check.process(""))
        }
    }
}
