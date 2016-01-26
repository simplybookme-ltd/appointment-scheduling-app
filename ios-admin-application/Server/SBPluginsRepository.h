//
//  SBPluginsRepository.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 11.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSBPluginRepositoryApproveBookingPlugin;
extern NSString * const kSBPluginRepositoryPaidEventsPlugin;
extern NSString * const kSBPluginRepositoryStatusPlugin;
extern NSString * const kSBPluginRepositorySimplySmartPromotionsPlugin;
extern NSString * const kSBPluginRepositoryLocationsPlugin;
extern NSString * const kSBPluginRepositoryAdditionalFieldsPlugin;
extern NSString * const kSBPluginRepositoryUnitColorPlugin;
extern NSString * const kSBPluginRepositoryServiceCategoriesPlugin;

extern NSString * const kSBBookingInfoApproveStatusNew;
extern NSString * const kSBBookingInfoApproveStatusApproved;
extern NSString * const kSBBookingInfoApproveStatusCancelled;

@interface SBPluginsRepository : NSObject

+ (nullable instancetype)repository;

- (NSNumber *)isPluginEnabled:(NSString *)pluginIdentifier;
- (void)setPlugin:(NSString *)pluginIdentifier enabled:(BOOL)enabled;

- (void)reset;

@end

NS_ASSUME_NONNULL_END