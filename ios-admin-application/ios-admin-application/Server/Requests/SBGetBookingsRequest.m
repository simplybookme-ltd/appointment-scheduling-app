//
//  SBGetBookingsRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetBookingsRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBBooking.h"

@interface SBGetBookingsResultProcessor : SBResultProcessor

@end

@implementation SBGetBookingsRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof(self) copy = [super copyWithToken:token];
    copy.filter = self.filter;
    return copy;
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]]
            addResultProcessorToChain:[SBGetBookingsResultProcessor new]];
}

- (NSString *)method
{
    return @"getBookings";
}

- (NSArray *)params
{
    return @[[self.filter encodedObject]];
}

- (NSData *)cacheKey
{
    NSError *error = nil;
    NSDictionary *filter = [self.filter encodedObject];
    NSMutableDictionary *hashObject = [NSMutableDictionary dictionary];
    hashObject[@"method"] = [self method];
    if (self.filter.from) {
        hashObject[@"date_from"] = filter[@"date_from"];
    }
    if (self.filter.to) {
        hashObject[@"date_to"] = filter[@"date_to"];
    }
    if (self.filter.limit) {
        hashObject[@"limit"] = filter[@"limit"];
    }
    if (self.filter.order) {
        hashObject[@"order"] = filter[@"order"];
    }
    return [NSJSONSerialization dataWithJSONObject:hashObject options:0 error:&error];
}

@end

@implementation SBGetBookingsResultProcessor

- (BOOL)process:(id)result
{
    if ([result count] > 0 && ![[result objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {
        NSString *localizedDescription = [NSString stringWithFormat:@"Unexpected result type of booking object. '%@' expected, '%@' occurred.",
                                          NSStringFromClass([NSDictionary class]), NSStringFromClass([[result objectAtIndex:0] class])];
        self.error = [NSError errorWithDomain:SBRequestErrorDomain code:SBUnknownErrorCode userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
        return NO;
    }
    NSMutableArray *bookings = [NSMutableArray array];
    for (NSDictionary *booking in result) {
        [bookings addObject:[[SBBooking alloc] initWithDict:booking]];
    }
    self.result = [bookings sortedArrayWithOptions:NSSortConcurrent usingComparator:^(SBBooking *booking1, SBBooking *booking2) {
        return [booking1.startDate compare:booking2.startDate];
    }];
    return YES;
}

@end