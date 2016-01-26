//
//  SBPerformer.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBPerformer.h"
#import "SBPluginsRepository.h"

@interface SBPerformer ()

- (instancetype)initWithDict:(NSDictionary *)dict;

@end

@implementation SBPerformer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.performerID = @"0";
        self.position = @0;
        self.picturePath = @"";
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
             @"can't create performer without id");
    self = [super init];
    if (self) {
        self.performerID = dict[@"id"];
        self.name = SAFE_KEY(dict,@"name");
        self.performerDescription = SAFE_KEY(dict,@"description");
        self.email = SAFE_KEY(dict,@"email");
        self.phone = SAFE_KEY(dict,@"phone");
        self.picture = SAFE_KEY(dict,@"picture");
        self.picturePath = SAFE_KEY(dict,@"picture_path");
        self.position = (SAFE_KEY(dict,@"position") ? @([dict[@"position"] integerValue]) : @0);
        self.color = SAFE_KEY(dict,@"color");
        self.isActive = (SAFE_KEY(dict,@"is_active") ? @([dict[@"is_active"] boolValue]) : nil);;
        self.isVisible = (SAFE_KEY(dict,@"is_visible") ? @([dict[@"is_visible"] boolValue]) : nil);;

        if (self.color && [self.color isEqualToString:@""]) {
            self.color = nil;
        }
        else {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryUnitColorPlugin enabled:YES];
        }
    }
    return self;
}

- (NSString *)id
{
    return self.performerID;
}

- (id)primarySortingField
{
    return self.position;
}

- (id)secondarySortingField
{
    return [self.name lowercaseString];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p: %@, %@>", NSStringFromClass([self class]), self, self.id, self.name];
}

@end

@implementation SBPerformerEntryBuilder

- (NSObject<SBCollectionEntryProtocol,SBCollectionSortingProtocol> *)entry
{
    return [[SBPerformer alloc] init];
}

- (NSObject<SBCollectionEntryProtocol,SBCollectionSortingProtocol> *)entryWithDict:(NSDictionary<NSString *,id> *)dict
{
    return [[SBPerformer alloc] initWithDict:dict];
}

@end
