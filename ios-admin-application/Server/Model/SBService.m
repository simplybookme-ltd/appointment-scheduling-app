//
//  SBService.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBService.h"
#import "SBPluginsRepository.h"

@implementation SBService

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.serviceID = @"0";
        self.position = @0;
        self.picture = @"";
    }
    return self;
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    NSParameterAssert(dict != nil);
    if ([dict isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSAssert(dict[@"id"] != nil && ![dict[@"id"] isEqual:[NSNull null]] && ![dict[@"id"] isEqualToString:@""],
             @"can't create service without id");
    self = [super init];
    if (self) {
        self.serviceID = dict[@"id"];
        self.name = SAFE_KEY(dict, @"name");
        self.serviceDescription = SAFE_KEY(dict, @"description");
        self.picture = SAFE_KEY(dict, @"picture");
        self.picturePath = SAFE_KEY(dict, @"picture_path");
        self.position = (SAFE_KEY(dict,@"position") ? @([dict[@"position"] integerValue]) : @0);
        self.isActive = (SAFE_KEY(dict,@"is_active") ? @([dict[@"is_active"] boolValue]) : nil);
        self.isPublic = (SAFE_KEY(dict,@"is_public") ? @([dict[@"is_public"] boolValue]) : nil);
        self.isRecurring = (SAFE_KEY(dict,@"is_recurring") ? @([dict[@"is_recurring"] boolValue]) : nil);
        self.duration = (SAFE_KEY(dict,@"duration") ? @([dict[@"duration"] integerValue]) : @0);
        self.hideDuration = (SAFE_KEY(dict,@"hide_duration") ? @([dict[@"hide_duration"] boolValue]) : @NO);
        self.price = (SAFE_KEY(dict, @"price") ? @([dict[@"price"] floatValue]) : nil);
        self.currency = (SAFE_KEY(dict, @"currency") ? dict[@"currency"] : nil);
        self.unitMap = nil;
        if (SAFE_KEY(dict, @"unit_map")) {
            NSMutableDictionary *unitMap = [NSMutableDictionary dictionary];
            for (NSString *performerID in [dict[@"unit_map"] allKeys]) {
                if ([dict[@"unit_map"][performerID] isEqual:[NSNull null]]) {
                    unitMap[performerID] = self.duration;
                }
                else {
                    unitMap[performerID] = @([dict[@"unit_map"][performerID] integerValue]);
                }
            }
            self.unitMap = unitMap;
        }
        if (self.price) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryPaidEventsPlugin enabled:YES];
        }
        if (SAFE_KEY(dict, @"categories")) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryServiceCategoriesPlugin enabled:YES];
        }
    }
    return self;
}

- (id)primarySortingField
{
    return self.position;
}

- (id)secondarySortingField
{
    return [self.name lowercaseString];
}

- (NSString *)id
{
    return self.serviceID;
}

@end

@implementation SBServiceEntryBuilder

- (NSObject<SBCollectionEntryProtocol,SBCollectionSortingProtocol> *)entry
{
    return [[SBService alloc] init];
}

- (NSObject<SBCollectionEntryProtocol,SBCollectionSortingProtocol> *)entryWithDict:(NSDictionary<NSString *,id> *)dict
{
    return [[SBService alloc] initWithDict:dict];
}

@end
