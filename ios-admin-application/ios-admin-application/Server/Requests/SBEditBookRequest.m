//
//  SBEditBookRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 08.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBEditBookRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBAdditionalField.h"
#import "NSDateFormatter+ServerParser.h"

@interface SBEditBookRequest ()

@end

@implementation SBEditBookRequest

- (NSString *)method
{
    return @"editBook";
}

/**
 * editBook($shedulerId, $eventId, $unitId, $clientId, $startDate, $startTime, $endDate = null, $endTime = null, $clientTimeOffset = 0, $additional = array())
 * $clientTimeOffset allways 0 for admin
 */
- (NSArray *)params
{
    NSMutableDictionary *encodedFields = [NSMutableDictionary dictionary];
    for (SBAdditionalField *field in self.formData.additionalFields) {
        encodedFields[field.name] = field.value;
    }
    return @[self.formData.bookingID, self.formData.eventID, self.formData.unitID,
             self.formData.client[@"id"] ? self.formData.client[@"id"] : [NSNull null],
             [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.formData.startTime],
             [[NSDateFormatter sb_serverTimeFormatter] stringFromDate:self.formData.startTime],
             [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.formData.endTime],
             [[NSDateFormatter sb_serverTimeFormatter] stringFromDate:self.formData.endTime],
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
