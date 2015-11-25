//
//  SBSettings.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBSettings.h"

@interface SBSettings ()
{
    NSMutableDictionary *settings;
    NSString *identifier;
}

@end

@implementation SBSettings

- (instancetype)initWithCompanyLogin:(NSString *)companyLogin userLogin:(NSString *)userLogin
{
    self = [super init];
    if (self) {
        identifier = [NSString stringWithFormat:@"settigns-%@-%@", companyLogin, userLogin];
        [self readFromFile];
    }
    return self;
}

- (void)readFromFile
{
    settings = [NSMutableDictionary dictionaryWithContentsOfURL:[self storageURL]];
    if (!settings) {
        settings = [NSMutableDictionary dictionary];
        [self setObject:@YES forKey:kSBSettingsNotificationsEnabledKey];
    }
}

- (void)writeToFile
{
    [settings writeToURL:[self storageURL] atomically:YES];
}

- (NSURL *)storageURL
{
    NSParameterAssert(identifier != nil && ![identifier isEqualToString:@""]);
    return [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:identifier];
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    if (object == nil) {
        [settings removeObjectForKey:key];
    }
    else {
        settings[key] = object;
    }
    [self didChangeValueForKey:key];
}

- (id)objectForKey:(NSString *)key
{
    return settings[key];
}

- (id)valueForKeyPath:(NSString *)keyPath
{
    return [self objectForKey:keyPath];
}

@end
