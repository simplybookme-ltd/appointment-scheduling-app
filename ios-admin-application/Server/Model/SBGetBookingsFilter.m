//
//  SBGetBookingsFilter.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetBookingsFilter.h"
#import "NSDateFormatter+ServerParser.h"
#import "SBDateRange.h"
#import "SBPluginsRepository.h"

NSString * const kSBGetBookingsFilterOrderByRecordDate = @"record_date";
NSString * const kSBGetBookingsFilterOrderByStartDate = @"start_date";
NSString * const kSBGetBookingsFilterOrderByStartDateAsc = @"start_date_asc";

@protocol SBGetBookingsStatusOptions <NSObject>

- (NSUInteger)numberOfOptions;
- (NSUInteger)valueForDefaultOption;
- (NSString *)titleForOptionAtIndex:(NSUInteger)index;
- (NSString *)valueForOptionAtIndex:(NSUInteger)index;

@end

/**
 * Default booking type filter (approve bookings plugin not enabled).
 */
NS_ENUM(NSInteger, _SBGetBookingsDefaultStatusOptions)
{
    SBGetBookingsDefaultStatusOptionsAll,
    SBGetBookingsDefaultStatusOptionsNotCancelled,
    SBGetBookingsDefaultStatusOptionsCancelled,
    
    SBGetBookingsDefaultStatusOptionsCount,
    SBGetBookingsDefaultStatusOptionsDefault = SBGetBookingsDefaultStatusOptionsNotCancelled
};

@interface SBGetBookingsDefaultStatusOptions : NSObject <SBGetBookingsStatusOptions>

@end

/**
 * Booking type filter if approve bookings plugin is enabled.
 */
NS_ENUM(NSInteger, _SBGetBookingsApproveStatusOptions)
{
    SBGetBookingsApproveStatusOptionsTypeAll,
    SBGetBookingsApproveStatusOptionsTypeNotCancelled,
    SBGetBookingsApproveStatusOptionsTypeCancelled,
    SBGetBookingsApproveStatusOptionsTypeApproved,
    SBGetBookingsApproveStatusOptionsTypeNotApproved,
    SBGetBookingsApproveStatusOptionsTypeCancelledByAdmin,
//    SBGetBookingsApproveStatusOptionsTypeCancelledByClient,
    
    SBGetBookingsApproveStatusOptionsTypeCount,
    SBGetBookingsApproveStatusOptionsTypeDefault = SBGetBookingsApproveStatusOptionsTypeNotCancelled
};

@interface SBGetBookingsApproveStatusOptions : NSObject <SBGetBookingsStatusOptions>

@end

@interface SBGetBookingsFilter ()

@property (nonatomic, strong) NSObject<SBGetBookingsStatusOptions> *statusOptions;

@end

@implementation SBGetBookingsFilter

+ (instancetype)todayBookingsFilter
{
    SBGetBookingsFilter *filter = [[self alloc] init];
    filter.from = [NSDate date];
    filter.to = [NSDate date];
    return filter;
}

+ (instancetype)bookingFilterWithDateRange:(SBDateRange *)dateRange
{
    NSParameterAssert(dateRange != nil);
    SBGetBookingsFilter *filter = [[self alloc] init];
    filter.from = dateRange.start;
    filter.to = dateRange.end;
    return filter;
}

- (NSDictionary *)encodedObject
{
    NSMutableDictionary *obj = [NSMutableDictionary dictionary];
    if (self.from) {
        obj[@"date_from"] = [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.from];
    }
    if (self.to) {
        obj[@"date_to"] = [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.to];
    }
    if (self.createdFrom) {
        obj[@"created_date_from"] = [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.createdFrom];
    }
    if (self.createdTo) {
        obj[@"created_date_to"] = [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.createdTo];
    }
    if (self.unitGroupID) {
        obj[@"unit_group_id"] = self.unitGroupID;
    }
    if (self.eventID) {
        obj[@"event_id"] = self.eventID;
    }
    if (self.bookingType) {
        obj[@"booking_type"] = [self.statusOptions valueForOptionAtIndex:self.bookingType.integerValue];
    }
    if (self.order) {
        obj[@"order"] = self.order;
    }
    if (self.limit) {
        obj[@"limit"] = self.limit;
    }
    if (self.upcomingOnly) {
        obj[@"upcoming_only"] = self.upcomingOnly;
    }
    return obj;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([[[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryApproveBookingPlugin] boolValue]) {
            self.statusOptions = [SBGetBookingsApproveStatusOptions new];
        }
        else {
            self.statusOptions = [SBGetBookingsDefaultStatusOptions new];
        }
        self.bookingType = @([self.statusOptions valueForDefaultOption]);
    }
    return self;
}

- (void)reset
{
    self.bookingType = @([self.statusOptions valueForDefaultOption]);
    self.createdFrom = nil;
    self.createdTo = nil;
    self.unitGroupID = nil;
    self.eventID = nil;
    self.clientID = nil;
    self.order = nil;
    self.limit = nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    SBGetBookingsFilter *copy = [[self class] allocWithZone:zone];
    copy.statusOptions = self.statusOptions;
    copy.from = self.from;
    copy.to = self.to;
    copy.createdFrom = self.createdFrom;
    copy.createdTo = self.createdTo;
    copy.unitGroupID = self.unitGroupID;
    copy.eventID = self.eventID;
    copy.clientID = self.clientID;
    copy.bookingType = self.bookingType;
    copy.order = self.order;
    copy.limit = self.limit;
    copy.upcomingOnly = self.upcomingOnly;
    return copy;
}

- (BOOL)isEqual:(SBGetBookingsFilter *)other
{
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[SBGetBookingsFilter class]]) {
        return NO;
    } else {
        return [self.unitGroupID isEqualToString:other.unitGroupID]
        && [self.eventID isEqualToString:other.eventID]
        && [self.clientID isEqualToNumber:other.clientID]
        && [self.order isEqualToString:other.order]
        && [self.limit isEqualToNumber:other.limit]
        && [self.upcomingOnly isEqualToNumber:other.upcomingOnly]
        && [self.bookingType isEqualToNumber:other.bookingType];
    }
}

#pragma mark - Booking type options

- (NSUInteger)numberOfBookingTypeOptions
{
    NSAssert(self.statusOptions != nil, @"filter not configured");
    return [self.statusOptions numberOfOptions];
}

- (NSString *)titleForBookingTypeOptionAtIndex:(NSInteger)index
{
    NSAssert(self.statusOptions != nil, @"filter not configured");
    return [self.statusOptions titleForOptionAtIndex:index];
}

@end

#pragma mark -

@implementation SBGetBookingsDefaultStatusOptions

- (NSUInteger)numberOfOptions
{
    return SBGetBookingsDefaultStatusOptionsCount;
}

- (NSUInteger)valueForDefaultOption
{
    return SBGetBookingsDefaultStatusOptionsDefault;
}

- (NSString *)titleForOptionAtIndex:(NSUInteger)index
{
    switch (index) {
        case SBGetBookingsDefaultStatusOptionsAll:
            return NSLS(@"All",@"");
        case SBGetBookingsDefaultStatusOptionsNotCancelled:
            return NSLS(@"Non Cancelled",@"");
        case SBGetBookingsDefaultStatusOptionsCancelled:
            return NSLS(@"Cancelled",@"");
        default:
            NSAssertFail();
            break;
    }
    return nil;
}

- (NSString *)valueForOptionAtIndex:(NSUInteger)index
{
    switch (index) {
        case SBGetBookingsDefaultStatusOptionsAll:
            return @"all";
        case SBGetBookingsDefaultStatusOptionsNotCancelled:
            return @"non_cancelled";
        case SBGetBookingsDefaultStatusOptionsCancelled:
            return @"cancelled";
        default:
            NSAssertFail();
            break;
    }
    return nil;
}

@end

#pragma mark -

@implementation SBGetBookingsApproveStatusOptions

- (NSUInteger)numberOfOptions
{
    return SBGetBookingsApproveStatusOptionsTypeCount;
}

- (NSUInteger)valueForDefaultOption
{
    return SBGetBookingsApproveStatusOptionsTypeDefault;
}

- (NSString *)titleForOptionAtIndex:(NSUInteger)index
{
    switch (index) {
        case SBGetBookingsApproveStatusOptionsTypeAll:
            return NSLS(@"All",@"");
        case SBGetBookingsApproveStatusOptionsTypeNotCancelled:
            return NSLS(@"Non Cancelled",@"");
        case SBGetBookingsApproveStatusOptionsTypeCancelled:
            return NSLS(@"Cancelled",@"");
        case SBGetBookingsApproveStatusOptionsTypeApproved:
            return NSLS(@"Approved by Admin",@"");
        case SBGetBookingsApproveStatusOptionsTypeNotApproved:
            return NSLS(@"Pending (not approved yet)",@"");
        case SBGetBookingsApproveStatusOptionsTypeCancelledByAdmin:
            return NSLS(@"Cancelled by Admin",@"");
//        case SBGetBookingsApproveStatusOptionsTypeCancelledByClient:
//            return NSLS(@"Cancelled by client",@"");
        default:
            NSAssertFail();
            break;
    }
    return nil;
}

- (NSString *)valueForOptionAtIndex:(NSUInteger)index
{
    switch (index) {
        case SBGetBookingsApproveStatusOptionsTypeAll:
            return @"all";
        case SBGetBookingsApproveStatusOptionsTypeNotCancelled:
            return @"non_cancelled";
        case SBGetBookingsApproveStatusOptionsTypeCancelled:
            return @"cancelled";
        case SBGetBookingsApproveStatusOptionsTypeApproved:
            return @"approved";
        case SBGetBookingsApproveStatusOptionsTypeNotApproved:
            return @"non_approved_yet";
        case SBGetBookingsApproveStatusOptionsTypeCancelledByAdmin:
            return @"cancelled_by_admin";
//        case SBGetBookingsApproveStatusOptionsTypeCancelledByClient:
//            return @"cancelled_by_client";
        default:
            NSAssertFail();
            break;
    }
    return nil;
}

@end
