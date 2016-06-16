//
//  SBBooking.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 15.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBBooking.h"
#import "NSDateFormatter+ServerParser.h"
#import "SBPluginsRepository.h"

@implementation SBBooking

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.bookingID = SAFE_KEY(dict, @"id");
        self.clientName = SAFE_KEY(dict, @"client");
        self.clientID = SAFE_KEY(dict, @"client_id");
        self.clientPhone = SAFE_KEY(dict, @"client_phone");
        self.clientEmail = SAFE_KEY(dict, @"client_email");
        self.startDate = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:SAFE_KEY(dict, @"start_date")];
        self.endDate = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:SAFE_KEY(dict, @"end_date")];
        self.recordDate = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:SAFE_KEY(dict, @"record_date")];
        self.performerName = SAFE_KEY(dict, @"unit");
        self.performerID = SAFE_KEY(dict, @"unit_id");
        self.eventTitle = SAFE_KEY(dict, @"event");
        self.isConfirmed = @([SAFE_KEY(dict, @"is_confirm") isEqualToString:@"1"]);
        self.statusID = SAFE_KEY(dict, @"status");
        self.paymentStatus = SAFE_KEY(dict, @"payment_status");
        self.paymentSystem = SAFE_KEY(dict, @"payment_system");

        /// if some fields contains value then we can say that some plugins enabled
        if (dict[@"status"]) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryStatusPlugin enabled:YES];
        }
        if (dict[@"approve_status"]) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryApproveBookingPlugin enabled:YES];
        }
        if (dict[@"payment_status"]) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryPaidEventsPlugin enabled:YES];
        }
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"id: %@; %@ - %@ (duration: %f)", self.bookingID, self.startDate, self.endDate, (self.endDate.timeIntervalSince1970 - self.startDate.timeIntervalSince1970)/60.];
    [description appendString:@">"];
    return description;
}

@end
