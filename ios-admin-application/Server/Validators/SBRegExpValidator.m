//
//  SBRegExpValidator.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRegExpValidator.h"

@interface SBPhoneNumberValidator : SBRegExpValidator

@property (nonatomic) BOOL formattedNumber;

@end

@interface SBRegExpValidator ()

@property (nonatomic, copy) NSString *regExpPattern;

@end

@implementation SBRegExpValidator

+ (instancetype)emailAddressValidator
{
    return [[self alloc] initWithPattern:@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"];
}

+ (instancetype)phoneNumberValidator:(BOOL)formattedNumber
{
    SBPhoneNumberValidator *validator = [[SBPhoneNumberValidator alloc] initWithPattern:@"^((\\+)|(00))[0-9]{6,14}$"];
    validator.formattedNumber = formattedNumber;
    return validator;
}

- (instancetype)initWithPattern:(NSString *)regExpPattern
{
    NSParameterAssert(regExpPattern != nil);
    self = [super init];
    if (self) {
        self.regExpPattern = regExpPattern;
    }
    return self;
}

- (BOOL)isValid:(NSString *)value
{
    if (![value isKindOfClass:[NSString class]]) {
        return NO;
    }
    NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", self.regExpPattern];
    return [test evaluateWithObject:value] ;
}

@end

@implementation SBPhoneNumberValidator

- (BOOL)isValid:(id)value
{
    if (!self.formattedNumber) {
        return [super isValid:value];
    }
    else {
        NSString *testValue = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789+-()[] "];
        return [testValue rangeOfCharacterFromSet:charSet].location != NSNotFound && [testValue rangeOfCharacterFromSet:[charSet invertedSet]].location == NSNotFound;
    }
}

@end