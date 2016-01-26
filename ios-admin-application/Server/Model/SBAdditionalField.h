//
//  SBAdditionalField.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 04.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSBAdditionalFieldCheckboxValueTrue @"on"
#define kSBAdditionalFieldCheckboxValueFalse @"off"

/** 
 * WARNING!
 * Do not change values of this ENUM. This values stored to Core Data database.
 * Changes of these values can affect work of application with already stored data.
 */
typedef NS_ENUM(NSInteger, SBAdditionalFieldType)
{
    SBAdditionalFieldUndefinedType = 0,
    SBAdditionalFieldDigitsType = 1,
    SBAdditionalFieldTextType = 2,
    SBAdditionalFieldTextareaType = 3,
    SBAdditionalFieldCheckboxType = 4,
    SBAdditionalFieldSelectType = 5
};

@protocol SBAdditionalFieldProtocol <NSObject>

@property (nonatomic, readonly) BOOL isNull;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSNumber *type;
@property (nonatomic, readonly) NSNumber *position;
@property (nonatomic, readonly) id defaultValue;
@property (nonatomic, strong) id value;

- (BOOL)isValid;

@end

@interface SBAdditionalField : NSObject <SBAdditionalFieldProtocol, NSCopying>

@property (nonatomic, readonly) NSInteger fieldID;
@property (nonatomic, readonly) BOOL isNull;
@property (nonatomic, readonly) NSNumber *position;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSNumber *type;
@property (nonatomic, readonly) NSArray *values;
@property (nonatomic, readonly) id defaultValue;
@property (nonatomic, strong) id value;

+ (NSInteger)typeFromString:(NSString *)typeName;

- (instancetype)initWithDict:(NSDictionary *)dict;
- (BOOL)isValid;

@end
