//
//  SBSettings.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kSBSettingsDeviceTokenKey;
extern NSString * const kSBSettingsNotificationsEnabledKey;
extern NSString * const kSBSettingsCalendarFirstWeekdayKey;

@interface SBSettings : NSObject

- (instancetype)initWithCompanyLogin:(NSString *)companyLogin userLogin:(NSString *)userLogin;

- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;

@end
