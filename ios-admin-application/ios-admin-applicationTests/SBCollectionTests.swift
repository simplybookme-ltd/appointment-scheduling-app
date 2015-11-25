//
//  SBPerformersCollectionTests.swift
//  ios-admin-application
//
//  Created by Michail Grebionkin on 20.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

import XCTest

class SBCollectionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformersCollection() {
        let data = [
            "1" : [ "color" : "#e07b7b",
                "description" : "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                "email" : NSNull(),
                "id" : "1",
                "is_active" : "1",
                "is_visible" : "1",
                "name" : "Michail",
                "phone" : "4400",
                "picture" : NSNull(),
                "picture_path" : "/uploads/testzt/unit_group__picture/small/",
                "position" : "1",
                "qty" : "1",
                "station_id" : "1", ],
            "2" : [ "color" : "#96d477",
                "description" : NSNull(),
                "email" : NSNull(),
                "id" : "2",
                "is_active" : "1",
                "is_visible" : "1",
                "name" : "Vladimir",
                "phone" : "44",
                "picture" : NSNull(),
                "picture_path" : "/uploads/testzt/unit_group__picture/small/",
                "position" : "0",
                "qty" : "10",
                "station_id" : "1", ],
            "3" : [ "color" : "#85bff2",
                "description" : NSNull(),
                "email" : NSNull(),
                "id" : "3",
                "is_active" : "1",
                "is_visible" : "1",
                "name" : "John",
                "phone" : "44",
                "picture" : NSNull(),
                "picture_path" : "/uploads/testzt/unit_group__picture/small/",
                "position" : "1",
                "qty" : "2",
                "station_id" : "1", ],
            "4" : [ "color" : "#d3e685",
                "description" : NSNull(),
                "email" : NSNull(),
                "id" : "4",
                "is_active" : "1",
                "is_visible" : "1",
                "name" : "Nataly",
                "phone" : "44",
                "picture" : NSNull(),
                "picture_path" : "/uploads/testzt/unit_group__picture/small/",
                "position" : "1",
                "qty" : "1",
                "station_id" : "1", ],
            "5" : [ "color" : "",
                "description" : NSNull(),
                "email" : NSNull(),
                "id" : "5",
                "is_active" : "1",
                "is_visible" : "1",
                "name" : "book days",
                "phone" : NSNull(),
                "picture" : NSNull(),
                "picture_path" : "/uploads/testzt/unit_group__picture/small/",
                "position" : "1",
                "qty" : "1",
                "station_id" : "1", ] ]
        let performersCollection : SBCollection? = SBCollection(dictionary: data, builder: SBPerformerEntryBuilder())
        XCTAssertNotNil(performersCollection)
        if let performersCollection = performersCollection {
            XCTAssertTrue(performersCollection.count() > 0)
            XCTAssertTrue(performersCollection.count() == 5)
            XCTAssertTrue(performersCollection.count() == UInt(data.count))
            XCTAssertNotNil(performersCollection[0])
            XCTAssertNotNil(performersCollection[0].id)
            XCTAssertNotNil(performersCollection[0].primarySortingField)
            XCTAssertNotNil(performersCollection["2"])
            if let performer = performersCollection["2"] {
                XCTAssertTrue(performer.id == "2")
                XCTAssertTrue(performersCollection.indexForObject(performer) == 0)
            }
            XCTAssertNotNil(performersCollection["5"])
            if let performer = performersCollection["5"] {
                XCTAssertTrue(performer.id == "5")
                XCTAssertTrue(performersCollection.indexForObject(performer) == 1)
            }
        }
    }
    
    func testServicesCollection() {
        let data = [
            "3" : [ "categories" : [ NSNull() ],
                "description" : "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                "duration" : "90",
                "hide_duration" : "0",
                "id" : "3",
                "is_active" : "1",
                "is_public" : "1",
                "is_recurring" : "0",
                "name" : "Test ZT 3",
                "picture" : "31450245f7003931c9f408d5a4324aaa.jpg",
                "picture_path" : "/uploads/testzt/event__picture/small/31450245f7003931c9f408d5a4324aaa.jpg",
                "position" : "1", ],
            "4" : [ "categories" : [ NSNull() ],
                "description" : NSNull(),
                "duration" : "30",
                "hide_duration" : "0",
                "id" : "4",
                "is_active" : "1",
                "is_public" : "1",
                "is_recurring" : "0",
                "name" : "Hair cut",
                "picture" : NSNull(),
                "picture_path" : "/uploads/testzt/event__picture/small/",
                "position" : "2", ],
            "5" : [ "categories" : [ NSNull() ],
                "description" : NSNull(),
                "duration" : "60",
                "hide_duration" : "0",
                "id" : "5",
                "is_active" : "1",
                "is_public" : "1",
                "is_recurring" : "0",
                "name" : "Massage",
                "picture" : NSNull(),
                "picture_path" : "/uploads/testzt/event__picture/small/",
                "position" : "0", ],
            "6" : [
                "categories" : [ NSNull() ],
                "description" : NSNull(),
                "duration" : "180",
                "hide_duration" : "0",
                "id" : "6",
                "is_active" : "1",
                "is_public" : "1",
                "is_recurring" : "0",
                "name" : "book days",
                "picture" : NSNull(),
                "picture_path" : "/uploads/testzt/event__picture/small/",
                "position" : "5",
                "unit_map" : [ "5" : NSNull(), ] ] ]
        let collection = SBCollection(dictionary: data, builder: SBServiceEntryBuilder())
        XCTAssertNotNil(collection)
        if let collection = collection {
            XCTAssertTrue(collection.count() > 0)
            XCTAssertTrue(collection.count() == 4)
            XCTAssertTrue(collection.count() == UInt(data.count))
            XCTAssertNotNil(collection[0])
            XCTAssertNotNil(collection[0].id)
            XCTAssertNotNil(collection[0].primarySortingField)
            XCTAssertNotNil(collection["6"])
            if let service = collection["6"] {
                XCTAssertTrue(service.id == "6")
                XCTAssertTrue(collection.indexForObject(service) == collection.count()-1)
            }
            XCTAssertNotNil(collection["5"])
            if let service = collection["5"] {
                XCTAssertTrue(service.id == "5")
                XCTAssertTrue(collection.indexForObject(service) == 0)
            }
        }
    }
}
