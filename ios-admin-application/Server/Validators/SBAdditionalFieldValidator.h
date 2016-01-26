//
//  SBAdditionalFieldValidator.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 04.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBValidator.h"

@interface SBAdditionalFieldValidator : SBValidator

@property (nonatomic) BOOL isMandatory;

+ (nullable instancetype)validatorForFieldType:(NSInteger)type values:(nullable NSArray *)values mandatory:(BOOL)mandatory;
+ (nullable instancetype)validatorForFieldType:(NSInteger)type mandatory:(BOOL)mandatory;

@end
