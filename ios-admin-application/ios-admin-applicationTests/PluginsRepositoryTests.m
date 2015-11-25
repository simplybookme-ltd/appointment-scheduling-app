//
//  PluginsRepositoryTests.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 11.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SBBookingInfo.h"
#import "SBPluginsRepository.h"
#import "SBBooking.h"

@interface PluginsRepositoryTests : XCTestCase

@end

@implementation PluginsRepositoryTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPluginsDetectionFromBookingDetails {
    NSDictionary *dict = @{
                           @"additional_fields" : @[ @{ @"field_id" : @"4",
                                                        @"field_name" : @"201a89517de509f6b3a60858918faac3",
                                                        @"field_position" : @"4",
                                                        @"field_title" : @"Include washing",
                                                        @"field_type" : @"checkbox",
                                                        @"value" : @"1"
                                                        } ],
                           @"client_id" : [NSNull null],
                           @"client_name" : [NSNull null],
                           @"code" : @"h8v77f0s",
                           @"comment" : [NSNull null],
                           @"comments" : @[],
                           @"company_email" : @"mihato.kun@gmail.com",
                           @"company_login" : @"testzt",
                           @"company_name" : @"My Cool Company",
                           @"company_phone" : @"+380",
                           @"end_date_time" : @"2015-11-09 17:00:00",
                           @"event_id" : @"4",
                           @"event_name" : @"Hair cut",
                           @"history" : @[ @{ @"agent" : @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.7",
                                              @"datetime" : @"2015-11-10 00:40:25",
                                              @"firstname" : @"Michail",
                                              @"id" : @"457",
                                              @"ip" : @"213.174.0.53, 198.27.74.48:127.0.0.1",
                                              @"lastname" : @" ",
                                              @"login" : @"admin",
                                              @"referer" : @"https://testzt.secure.simplybook.me/v2/",
                                              @"sheduler_id" : @"260",
                                              @"type" : @"edit",
                                              @"user_id" : @"1"
                                              } ],
                           @"id" : @"260",
                           @"is_confirmed" : @"1",
                           @"location" : @{ @"address1" : [NSNull null],
                                            @"address2" : @"Old Pye Street, 18",
                                            @"city" : @"city",
                                            @"country_id" : @"GB",
                                            @"description" : [NSNull null],
                                            @"id" : @"2",
                                            @"is_default" : @"0",
                                            @"lat" : @"51.49761868756322500000",
                                            @"lng" : @"-0.13076819580078336000",
                                            @"phone" : @"44",
                                            @"picture" : @"d1a1c206db269d32ed5005ac3f303b1a.png",
                                            @"position" : @"1",
                                            @"title" : @"location 2",
                                            @"zip" : [NSNull null]
                                            },
                           @"price" : @[ ],
                           @"promo" : @[ ],
                           @"record_date" : @"2015-11-09 06:17:18",
                           @"start_date_time" : @"2015-11-09 14:30:00",
                           @"status" : @{ @"color" : @"ff0000",
                                          @"description" : [NSNull null],
                                          @"id" : @"3",
                                          @"is_default" : @"1",
                                          @"name" : @"Approved"
                                          },
                           @"unit_id" : @"2",
                           @"unit_name" : @"Vladimir"
                           };
    [[SBPluginsRepository repository] reset];
    SBBookingInfo *bookingInfo = [[SBBookingInfo alloc] initWithDict:dict];
    XCTAssertNotNil(bookingInfo);
    XCTAssertNotNil([[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryLocationsPlugin]);
    XCTAssertTrue([[[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryLocationsPlugin] boolValue]);
    XCTAssertNotNil([[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryStatusPlugin]);
    XCTAssertTrue([[[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryStatusPlugin] boolValue]);
    XCTAssertNotNil([[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryAdditionalFieldsPlugin]);
    XCTAssertTrue([[[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryAdditionalFieldsPlugin] boolValue]);
    XCTAssertNil([[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositorySimplySmartPromotionsPlugin]);
    XCTAssertNil([[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryApproveBookingPlugin]);
    XCTAssertNil([[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryPaidEventsPlugin]);
}

@end
