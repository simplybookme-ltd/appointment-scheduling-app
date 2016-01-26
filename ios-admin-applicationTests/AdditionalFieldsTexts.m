//
//  AdditionalFieldsTexts.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 22.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SBAdditionalField.h"

@interface AdditionalFieldsTexts : XCTestCase

@end

@implementation AdditionalFieldsTexts

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSelect {
    NSDictionary *fieldData = @{
                                @"default" : [NSNull null],
                                @"id" : @9,
                                @"is_null" : [NSNull null],
                                @"length" : [NSNull null],
                                @"name" : @"81853bf002e30056f6189432c77d98a5",
                                @"on_main_page" : [NSNull null],
                                @"plugin_event_field_value_id" : [NSNull null],
                                @"pos" : @9,
                                @"title" : @"select",
                                @"type" : @"select",
                                @"value" : [NSNull null],
                                @"values" : @"one, two, three, four, five"
                                };
    SBAdditionalField *selectField = [[SBAdditionalField alloc] initWithDict:fieldData];
    XCTAssertNotNil(selectField);
    XCTAssertFalse([selectField isValid]);
    XCTAssertNotNil(selectField.values);
    XCTAssertEqual(selectField.type.integerValue, SBAdditionalFieldSelectType);
    
    selectField.value = @"ten";
    XCTAssertFalse([selectField isValid]);
    
    selectField.value = @"one";
    XCTAssertTrue([selectField isValid]);
}

- (void)testTextfield {
    NSDictionary *fieldData = @{
                                @"default" : [NSNull null],
                                @"id" : @9,
                                @"is_null" : [NSNull null],
                                @"length" : [NSNull null],
                                @"name" : @"81853bf002e30056f6189432c77d98a5",
                                @"on_main_page" : [NSNull null],
                                @"plugin_event_field_value_id" : [NSNull null],
                                @"pos" : @9,
                                @"title" : @"textfield",
                                @"type" : @"text",
                                @"value" : [NSNull null],
                                @"values" : [NSNull null]
                                };
    SBAdditionalField *textField = [[SBAdditionalField alloc] initWithDict:fieldData];
    XCTAssertNotNil(textField);
    XCTAssertFalse([textField isValid]);
    XCTAssertEqual(textField.type.integerValue, SBAdditionalFieldTextType);
    
    textField.value = @"  ";
    XCTAssertFalse([textField isValid]);
    
    textField.value = @"some string value ";
    XCTAssertTrue([textField isValid]);
}

- (void)testMandatoryCheckbox {
    NSDictionary *fieldData = @{
                                @"default" : [NSNull null],
                                @"id" : @9,
                                @"is_null" : [NSNull null],
                                @"length" : [NSNull null],
                                @"name" : @"81853bf002e30056f6189432c77d98a5",
                                @"on_main_page" : [NSNull null],
                                @"plugin_event_field_value_id" : [NSNull null],
                                @"pos" : @9,
                                @"title" : @"title",
                                @"type" : @"checkbox",
                                @"value" : [NSNull null],
                                @"values" : [NSNull null]
                                };
    SBAdditionalField *checkboxField = [[SBAdditionalField alloc] initWithDict:fieldData];
    XCTAssertNotNil(checkboxField);
    XCTAssertFalse([checkboxField isValid]);
    XCTAssertEqual(checkboxField.type.integerValue, SBAdditionalFieldCheckboxType);
    
    checkboxField.value = kSBAdditionalFieldCheckboxValueFalse;
    XCTAssertFalse([checkboxField isValid]);
    
    checkboxField.value = kSBAdditionalFieldCheckboxValueTrue;
    XCTAssertTrue([checkboxField isValid]);
}

- (void)testNotMandatoryCheckbox {
    NSDictionary *fieldData = @{
                                @"default" : [NSNull null],
                                @"id" : @9,
                                @"is_null" : @"1",
                                @"length" : [NSNull null],
                                @"name" : @"81853bf002e30056f6189432c77d98a5",
                                @"on_main_page" : [NSNull null],
                                @"plugin_event_field_value_id" : [NSNull null],
                                @"pos" : @9,
                                @"title" : @"title",
                                @"type" : @"checkbox",
                                @"value" : [NSNull null],
                                @"values" : [NSNull null]
                                };
    SBAdditionalField *checkboxField = [[SBAdditionalField alloc] initWithDict:fieldData];
    XCTAssertNotNil(checkboxField);
    XCTAssertTrue([checkboxField isValid]);
    XCTAssertEqual(checkboxField.type.integerValue, SBAdditionalFieldCheckboxType);
    
    checkboxField.value = kSBAdditionalFieldCheckboxValueFalse;
    XCTAssertTrue([checkboxField isValid]);
    
    checkboxField.value = kSBAdditionalFieldCheckboxValueTrue;
    XCTAssertTrue([checkboxField isValid]);
}

- (void)testTextarea {
    NSDictionary *fieldData = @{
                                @"default" : [NSNull null],
                                @"id" : @9,
                                @"is_null" : [NSNull null],
                                @"length" : [NSNull null],
                                @"name" : @"81853bf002e30056f6189432c77d98a5",
                                @"on_main_page" : [NSNull null],
                                @"plugin_event_field_value_id" : [NSNull null],
                                @"pos" : @9,
                                @"title" : @"textarea",
                                @"type" : @"textarea",
                                @"value" : [NSNull null],
                                @"values" : [NSNull null]
                                };
    SBAdditionalField *textareaField = [[SBAdditionalField alloc] initWithDict:fieldData];
    XCTAssertNotNil(textareaField);
    XCTAssertFalse([textareaField isValid]);
    XCTAssertEqual(textareaField.type.integerValue, SBAdditionalFieldTextareaType);
    
    textareaField.value = @"  ";
    XCTAssertFalse([textareaField isValid]);
    
    textareaField.value = @"some string value ";
    XCTAssertTrue([textareaField isValid]);
}

- (void)testDigits {
    NSDictionary *fieldData = @{
                                @"default" : [NSNull null],
                                @"id" : @9,
                                @"is_null" : [NSNull null],
                                @"length" : [NSNull null],
                                @"name" : @"81853bf002e30056f6189432c77d98a5",
                                @"on_main_page" : [NSNull null],
                                @"plugin_event_field_value_id" : [NSNull null],
                                @"pos" : @9,
                                @"title" : @"digits",
                                @"type" : @"digits",
                                @"value" : [NSNull null],
                                @"values" : [NSNull null]
                                };
    SBAdditionalField *textareaField = [[SBAdditionalField alloc] initWithDict:fieldData];
    XCTAssertNotNil(textareaField);
    XCTAssertFalse([textareaField isValid]);
    XCTAssertEqual(textareaField.type.integerValue, SBAdditionalFieldDigitsType);
    
    textareaField.value = @"  ";
    XCTAssertFalse([textareaField isValid]);
    
    textareaField.value = @"10adl82";
    XCTAssertFalse([textareaField isValid]);
    
    textareaField.value = @"10";
    XCTAssertTrue([textareaField isValid]);
    
    textareaField.value = @"10.5";
    XCTAssertTrue([textareaField isValid]);
}

- (void)testDigitsWithDefaultValue {
    NSDictionary *fieldData = @{
                                @"default" : @"10",
                                @"id" : @9,
                                @"is_null" : [NSNull null],
                                @"length" : [NSNull null],
                                @"name" : @"81853bf002e30056f6189432c77d98a5",
                                @"on_main_page" : [NSNull null],
                                @"plugin_event_field_value_id" : [NSNull null],
                                @"pos" : @9,
                                @"title" : @"digits",
                                @"type" : @"digits",
                                @"value" : [NSNull null],
                                @"values" : [NSNull null]
                                };
    SBAdditionalField *additionalField = [[SBAdditionalField alloc] initWithDict:fieldData];
    XCTAssertNotNil(additionalField);
    XCTAssertTrue([additionalField isValid]);
    XCTAssertEqual(additionalField.type.integerValue, SBAdditionalFieldDigitsType);
    
}

- (void)testDigitsMandatory {
    NSDictionary *fieldData = @{
                                @"default" : [NSNull null],
                                @"id" : @9,
                                @"is_null" : [NSNull null],
                                @"length" : [NSNull null],
                                @"name" : @"81853bf002e30056f6189432c77d98a5",
                                @"on_main_page" : [NSNull null],
                                @"plugin_event_field_value_id" : [NSNull null],
                                @"pos" : @9,
                                @"title" : @"digits",
                                @"type" : @"digits",
                                @"value" : [NSNull null],
                                @"values" : [NSNull null]
                                };
    SBAdditionalField *additionalField = [[SBAdditionalField alloc] initWithDict:fieldData];
    XCTAssertNotNil(additionalField);
    XCTAssertFalse([additionalField isValid]);
    XCTAssertEqual(additionalField.type.integerValue, SBAdditionalFieldDigitsType);
    additionalField.value = @"10";
    XCTAssertTrue([additionalField isValid]);
}

- (void)testTextareaMandatory {
    NSDictionary *fieldData = @{
                                @"default" : [NSNull null],
                                @"id" : @9,
                                @"is_null" : @1,
                                @"length" : [NSNull null],
                                @"name" : @"81853bf002e30056f6189432c77d98a5",
                                @"on_main_page" : [NSNull null],
                                @"plugin_event_field_value_id" : [NSNull null],
                                @"pos" : @9,
                                @"title" : @"textarea",
                                @"type" : @"textarea",
                                @"value" : [NSNull null],
                                @"values" : [NSNull null]
                                };
    SBAdditionalField *textareaField = [[SBAdditionalField alloc] initWithDict:fieldData];
    XCTAssertNotNil(textareaField);
    XCTAssertTrue([textareaField isValid]);
    XCTAssertEqual(textareaField.type.integerValue, SBAdditionalFieldTextareaType);
    
    textareaField.value = @"  ";
    XCTAssertTrue([textareaField isValid]);
    
    textareaField.value = @"some string value ";
    XCTAssertTrue([textareaField isValid]);
}

@end
