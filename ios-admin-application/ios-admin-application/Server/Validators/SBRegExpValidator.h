//
//  SBRegExpValidator.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBValidator.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBRegExpValidator : SBValidator

+ (nullable instancetype)emailAddressValidator;
+ (nullable instancetype)phoneNumberValidator:(BOOL)formattedNumber;

- (nullable instancetype)initWithPattern:(NSString *)regExpPattern;

@end

NS_ASSUME_NONNULL_END