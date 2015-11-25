//
//  NSDateFormatter+ServerParser.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateFormatter (ServerParser)

+ (instancetype)sb_serverDateTimeFormatter;
+ (instancetype)sb_serverDateFormatter;
+ (instancetype)sb_serverTimeFormatter;
+ (instancetype)sb_pushNotificationTimeParser;

@end
