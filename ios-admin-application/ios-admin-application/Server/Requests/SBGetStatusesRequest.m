//
//  SBGetStatuses.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetStatusesRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBBookingStatusesCollection.h"
#import "SBPluginsRepository.h"

@interface SBGetStatusesResponseProcessor : SBResultProcessor
@end

@implementation SBGetStatusesRequest

- (NSString *)method
{
    return @"getStatuses";
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]]
            addResultProcessorToChain:[SBGetStatusesResponseProcessor new]];
}

@end

@implementation SBGetStatusesResponseProcessor

- (BOOL)process:(NSArray *)result
{
    SBBookingStatusesCollection *statusesCollection = [[SBBookingStatusesCollection alloc] initWithStatusesList:result];
    if (statusesCollection.count > 0) {
        [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryStatusPlugin enabled:YES];
    }
    return [self chainResult:statusesCollection success:YES];
}

@end
