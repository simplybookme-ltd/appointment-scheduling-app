//
//  SBAdditionalField.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 04.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBAdditionalField.h"
#import "SBAdditionalFieldValidator.h"

@interface SBAdditionalField()

@property (nonatomic, readwrite) NSInteger fieldID;
@property (nonatomic, readwrite) BOOL isNull;
@property (nonatomic, readwrite) NSNumber *position;
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readwrite) NSNumber *type;
@property (nonatomic, readwrite) NSArray *values;
@property (nonatomic, readwrite) id defaultValue;
@property (nonatomic, strong) SBAdditionalFieldValidator *validator;

@end

@implementation SBAdditionalField

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.fieldID = [SAFE_KEY(dict, @"id") integerValue];
        self.isNull = [SAFE_KEY(dict, @"is_null") boolValue];
        self.position = SAFE_KEY(dict, @"pos");
        self.title = SAFE_KEY(dict, @"title");
        self.name = SAFE_KEY(dict, @"name");
        self.value = SAFE_KEY(dict, @"value");
        self.defaultValue = SAFE_KEY(dict, @"default");
        if (!self.value && self.defaultValue) {
            self.value = self.defaultValue;
        }
        if (dict[@"values"] && ![dict[@"values"] isEqual:[NSNull null]]) {
            self.values = [dict[@"values"] componentsSeparatedByString:@", "];
            if (self.values.count == 1 && [self.values[0] isEqualToString:dict[@"values"]]) {
                self.values = [dict[@"values"] componentsSeparatedByString:@","];
            }
        }
        self.type = @([[self class] typeFromString:SAFE_KEY(dict, @"type")]);
        if (self.type.integerValue == SBAdditionalFieldCheckboxType) {
            self.validator = [SBAdditionalFieldValidator validatorForFieldType:self.type.integerValue mandatory:(self.isNull ? NO : YES)];
        }
        else {
            self.validator = [SBAdditionalFieldValidator validatorForFieldType:self.type.integerValue values:self.values mandatory:(self.isNull ? NO : YES)];
        }
//        if (self.type.integerValue == SBAdditionalFieldCheckboxType && !self.value) {
//            self.value = kSBAdditionalFieldCheckboxValueFalse;
//        }
    }
    return self;
}

+ (NSInteger)typeFromString:(NSString *)typeName
{
    if ([typeName isEqualToString:@"select"]) {
        return SBAdditionalFieldSelectType;
    }
    else if ([typeName isEqualToString:@"checkbox"]) {
        return SBAdditionalFieldCheckboxType;
    }
    else if ([typeName isEqualToString:@"text"]) {
        return SBAdditionalFieldTextType;
    }
    else if ([typeName isEqualToString:@"textarea"]) {
        return SBAdditionalFieldTextareaType;
    }
    else if ([typeName isEqualToString:@"digits"]) {
        return SBAdditionalFieldDigitsType;
    }
    NSAssert(NO, @"undefined additional field type: '%@'", typeName);
    return SBAdditionalFieldUndefinedType;
}

- (BOOL)isValid
{
    return [self.validator isValid:self.value];
}

- (id)copyWithZone:(NSZone *)zone
{
    typeof(self) copy = [[self class] allocWithZone:zone];
    copy.fieldID = self.fieldID;
    copy.isNull = self.isNull;
    copy.position = [self.position copyWithZone:zone];
    copy.name = [self.name copyWithZone:zone];
    copy.title = [self.title copyWithZone:zone];
    copy.type = [self.type copyWithZone:zone];
    copy.values = self.values;
    if (self.defaultValue) {
        copy.value = [self.defaultValue copy];
    }
    copy.defaultValue = self.defaultValue;
    copy.validator = self.validator;
    return copy;
}

@end
