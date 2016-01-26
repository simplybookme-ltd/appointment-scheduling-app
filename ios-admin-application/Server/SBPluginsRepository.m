//
//  SBPluginsRepository.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 11.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBPluginsRepository.h"

NSString * _Nonnull const kSBBookingInfoApproveStatusNew = @"new";
NSString * _Nonnull const kSBBookingInfoApproveStatusApproved = @"approved";
NSString * _Nonnull const kSBBookingInfoApproveStatusCancelled = @"canceled";

/// @see http://wiki.simplybook.me/index.php/Plugins#Approve_booking
NSString * _Nonnull const kSBPluginRepositoryApproveBookingPlugin = @"approve_booking";

/// @see http://wiki.simplybook.me/index.php/Plugins#Accept_payments
NSString * _Nonnull const kSBPluginRepositoryPaidEventsPlugin = @"paid_events";

/// @see http://wiki.simplybook.me/index.php/Plugins#Status
NSString * _Nonnull const kSBPluginRepositoryStatusPlugin = @"status";

/// @see http://wiki.simplybook.me/index.php/Plugins#Simply_Smart_Promotions
NSString * _Nonnull const kSBPluginRepositorySimplySmartPromotionsPlugin = @"promo";

/// @see http://wiki.simplybook.me/index.php/Plugins#Unit_location
NSString * _Nonnull const kSBPluginRepositoryLocationsPlugin = @"location";

/// @see http://wiki.simplybook.me/index.php/Plugins#Additional_fields
NSString * _Nonnull const kSBPluginRepositoryAdditionalFieldsPlugin = @"event_field";

/// @see http://wiki.simplybook.me/index.php/Plugins#Provider.27s_color_coding_plugin
NSString * _Nonnull const kSBPluginRepositoryUnitColorPlugin = @"unit_colors";

/// @see http://wiki.simplybook.me/index.php/Plugins#Service_categories
NSString * const kSBPluginRepositoryServiceCategoriesPlugin = @"event_category";

@implementation SBPluginsRepository
{
    NSMutableDictionary <NSString *, NSNumber *> *repository;
}

+ (nullable instancetype)repository
{
    static dispatch_once_t onceToken;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (nullable instancetype)init
{
    self = [super init];
    if (self) {
        repository = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)isSet:(nonnull NSString *)pluginIdentifier
{
    NSParameterAssert(pluginIdentifier != nil);
    return repository[pluginIdentifier] != nil;
}

- (NSNumber *)isPluginEnabled:(nonnull NSString *)pluginIdentifier
{
    NSParameterAssert(pluginIdentifier != nil);
    return repository[pluginIdentifier];
}

- (void)setPlugin:(nonnull NSString *)pluginIdentifier enabled:(BOOL)enabled
{
    NSParameterAssert(pluginIdentifier != nil);
    repository[pluginIdentifier] = @(enabled);
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendString:[repository description]];
    [description appendString:@">"];
    return description;
}

- (void)reset
{
    [repository removeAllObjects];
}

@end
