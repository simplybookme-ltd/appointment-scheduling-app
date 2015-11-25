//
//  SBAdditionalFieldValidator.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 04.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBAdditionalFieldValidator.h"
#import "SBAdditionalField.h"

@interface SBAdditionalFieldDigitsValidator : SBAdditionalFieldValidator
@end

@interface SBAdditionalFieldSelectorValidator : SBAdditionalFieldValidator
@end

@interface SBAdditionalFieldNoValidator : SBAdditionalFieldValidator
@end

@interface SBAdditionalFieldCheckboxValidator : SBAdditionalFieldValidator
@end

@interface SBAdditionalFieldTextValidator : SBAdditionalFieldValidator
@end

@interface SBAdditionalFieldValidator ()

@property (nonatomic, strong, nullable) NSArray *values;

@end

@implementation SBAdditionalFieldValidator

+ (nullable instancetype)validatorForFieldType:(NSInteger)type values:(nullable NSArray *)values mandatory:(BOOL)mandatory
{
    switch (type) {
        case SBAdditionalFieldDigitsType:
            return [[SBAdditionalFieldDigitsValidator alloc] initWithValues:values mandatory:mandatory];
        case SBAdditionalFieldTextareaType:
        case SBAdditionalFieldTextType:
            return [[SBAdditionalFieldTextValidator alloc] initWithValues:nil mandatory:mandatory];
        case SBAdditionalFieldCheckboxType:
            return [[SBAdditionalFieldNoValidator alloc] initWithValues:nil mandatory:mandatory];
        case SBAdditionalFieldSelectType:
            return [[SBAdditionalFieldSelectorValidator alloc] initWithValues:values mandatory:mandatory];
        default:
            NSAssert(NO, @"unexpected additional field type: %ld", (long)type);
            break;
    }
    return nil;
}

+ (nullable instancetype)validatorForFieldType:(NSInteger)type mandatory:(BOOL)mandatory
{
    switch (type) {
        case SBAdditionalFieldCheckboxType:
            if (mandatory) {
                return [[SBAdditionalFieldCheckboxValidator alloc] initWithValues:nil mandatory:mandatory];
            } else {
                return [[SBAdditionalFieldNoValidator alloc] initWithValues:nil mandatory:mandatory];
            }
            break;
            
        default:
            break;
    }
    return [self validatorForFieldType:type values:nil mandatory:mandatory];
}

- (instancetype)initWithValues:(nullable NSArray *)values mandatory:(BOOL)mandatory
{
    self = [super init];
    if (self) {
        self.isMandatory = mandatory;
        self.values = values;
    }
    return self;
}

@end

#pragma mark -

@implementation SBAdditionalFieldDigitsValidator

- (BOOL)isValid:(id)value
{
    if (self.isMandatory && (value == nil || [value isEqualToString:@""])) {
        return NO;
    }
    else if (!self.isMandatory && (value == nil || [value isEqualToString:@""])) {
        return YES;
    }
    return [value rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound
    && [[value lowercaseString] rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].location == NSNotFound;
}

@end

@implementation SBAdditionalFieldSelectorValidator

- (BOOL)isValid:(id)value
{
    if (self.isMandatory && value == nil) {
        return NO;
    }
    else if (!self.isMandatory && (value == nil || self.values == nil || self.values.count == 0)) {
        return YES;
    }
    return [self.values containsObject:value];
}

@end

@implementation SBAdditionalFieldNoValidator

- (BOOL)isValid:(id)value
{
    return YES;
}

@end

@implementation SBAdditionalFieldCheckboxValidator

- (BOOL)isValid:(id)value
{
    return [value isEqualToString:kSBAdditionalFieldCheckboxValueTrue];
}

@end

@implementation SBAdditionalFieldTextValidator

- (BOOL)isValid:(id)value
{
    if (self.isMandatory && (value == nil || [[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])) {
        return NO;
    }
    else if (!self.isMandatory && (value == nil || [[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])) {
        return YES;
    }
    return [[[self class] notEmptyStringValidator] isValid:value];
}

@end