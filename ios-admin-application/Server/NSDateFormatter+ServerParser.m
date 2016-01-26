//
//  NSDateFormatter+ServerParser.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "NSDateFormatter+ServerParser.h"

@implementation NSDateFormatter (ServerParser)

+ (instancetype)sb_serverDateTimeFormatter
{
    static id dateTimeFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!dateTimeFormatter) {
            dateTimeFormatter = [self new];
            [dateTimeFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
            [dateTimeFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        }
    });
    return dateTimeFormatter;
}

+ (instancetype)sb_serverDateFormatter
{
    static id dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!dateFormatter) {
            dateFormatter = [self new];
            [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
            [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        }
    });
    return dateFormatter;
}

+ (instancetype)sb_serverTimeFormatter
{
    static id timeFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!timeFormatter) {
            timeFormatter = [self new];
            [timeFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
            [timeFormatter setDateFormat:@"HH:mm:ss"];
        }
    });
    return timeFormatter;
}

+ (instancetype)sb_pushNotificationTimeParser
{
    static id pushTimeParser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!pushTimeParser) {
            pushTimeParser = [self new];
            [pushTimeParser setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
            [pushTimeParser setDateFormat:@"dd-MM-yyyy HH:mm"];
        }
    });
    return pushTimeParser;
}

@end
