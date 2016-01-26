//
//  SBBookRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBBookRequest.h"
#import "SBRequestOperation_Private.h"
#import "NSDateFormatter+ServerParser.h"
#import "SBAdditionalField.h"

@interface SBBookRequest ()

@end

@implementation SBBookRequest

- (NSString *)method
{
    return @"book";
}

/**
 * book($eventId, $unitId, $clientId, $startDate, $startTime, $endDate = null, $endTime = null, $clientTimeOffset = 0, $additional = array(), $count = 1, $batchId = null, $recurringData = null)
 * $clientTimeOffset allways 0 for admin
 */
- (NSArray *)params
{
    NSMutableDictionary *encodedFields = [NSMutableDictionary dictionary];
    for (SBAdditionalField *field in self.formData.additionalFields) {
        encodedFields[field.name] = field.value;
    }
    return @[self.formData.eventID ? self.formData.eventID : @"0",
             self.formData.unitID ? self.formData.unitID : @"0",
             self.formData.client[@"id"] ? self.formData.client[@"id"] : [NSNull null],
             self.formData.startTime ? [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.formData.startTime] : @"1970-01-01",
             self.formData.startTime ? [[NSDateFormatter sb_serverTimeFormatter] stringFromDate:self.formData.startTime] : @"00:00",
             self.formData.endTime ? [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.formData.endTime] : @"1970-01-01",
             self.formData.endTime ? [[NSDateFormatter sb_serverTimeFormatter] stringFromDate:self.formData.endTime] : @"00:00",
             @"0", encodedFields
             ];
}

- (SBCachePolicy)cachePolicy
{
    return SBNoCachePolicy;
}

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.formData = self.formData;
    return copy;
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]];
}

@end
