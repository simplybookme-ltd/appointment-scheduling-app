//
//  CalendarBookingPresenter.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.10.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "CalendarBookingPresenter.h"
#import "UIColor+SimplyBookColors.h"
#import "SBBookingStatusesCollection.h"

@implementation CalendarBookingDefaultPresenter

+ (instancetype)presenter
{
    return [[self alloc] init];
}

- (UIColor *)backgroundColorForBooking:(NSObject<SBBookingProtocol> *)booking
{
    return [UIColor sb_defaultBookingColor];
}

@end

#pragma mark -

@interface CalendarBookingStatusPresenter ()

@property (nonatomic, strong) SBBookingStatusesCollection *statuses;

@end

@implementation CalendarBookingStatusPresenter

- (instancetype)initWithStatuses:(SBBookingStatusesCollection *)statuses
{
    NSParameterAssert(statuses != nil);
    self = [super init];
    if (self) {
        self.statuses = statuses;
    }
    return self;
}

- (UIColor *)backgroundColorForBooking:(NSObject<SBBookingProtocol> *)booking
{
    NSParameterAssert(booking != nil);
    if (booking.statusID) {
        SBBookingStatus *status = self.statuses[booking.statusID];
        if (status) {
            return [UIColor colorFromHEXString:status.HEXColor];
        }
    }
    else if (self.statuses.count > 0) {
        return [UIColor colorFromHEXString:self.statuses.defaultStatus.HEXColor];
    }
    return nil;
}

@end

#pragma mark -

@interface CalendarBookingPerformerPresenter ()

@property (nonatomic, strong) SBPerformersCollection *performers;

@end

@implementation CalendarBookingPerformerPresenter

- (instancetype)initWithPerformers:(SBPerformersCollection *)performers
{
    NSParameterAssert(performers != nil);
    self = [super init];
    if (self) {
        self.performers = performers;
    }
    return self;
}

- (UIColor *)backgroundColorForBooking:(NSObject<SBBookingProtocol> *)booking
{
    NSParameterAssert(booking != nil);
    if (self.performers[booking.performerID].color) {
        return [UIColor colorFromHEXString:self.performers[booking.performerID].color];
    }
    return nil;
}

@end
