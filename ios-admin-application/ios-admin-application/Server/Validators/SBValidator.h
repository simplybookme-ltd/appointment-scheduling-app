//
//  SBValidator.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBValidator : NSObject

+ (instancetype)notEmptyStringValidator;
+ (instancetype)notNullValidator;

- (BOOL)isValid:(id)value;

@end
