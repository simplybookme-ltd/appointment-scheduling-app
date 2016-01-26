//
//  DashboardBookingsWidget.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 30.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardBookingsWidget.h"
#import "UIColor+SimplyBookColors.h"
#import "SBSession.h"
#import "DashboardBookingCollectionViewCell.h"
#import "SBBooking.h"
#import "MessageCollectionReusableView.h"

NSString * const kDashboardBookingsWidgetCellReuseIdentifier = @"kDashboardBookingsWidgetCellReuseIdentifier";

@interface BookingsWidgetRecentSegment : DashboardSegmentDataSource

@property (nonatomic, strong) SBGetBookingsFilter *filter;
@property (nonatomic, strong) NSString *emptyDataString;

@end

@interface BookingsWidgetUpcomingSegment : BookingsWidgetRecentSegment
@end

@interface DashboardBookingsWidget ()
{
}

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateIntervalFormatter *intervalFormatter;

@end

@implementation DashboardBookingsWidget

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredWidgetHeight = 50;
        self.dataUpdateStrategy = [DashboardWidgetUpdateStrategy timerUpdateStrategyWithTimeInterval:60
                                                                                           forWidget:self];
        self.title = NSLS(@"Bookings",@"");
        self.color = [UIColor colorFromHEXString:@"#58c9f3"];
        
        BookingsWidgetUpcomingSegment *upcomingBookingDS = [BookingsWidgetUpcomingSegment new];
        upcomingBookingDS.title = NSLS(@"Upcoming", @"");
        upcomingBookingDS.emptyDataString = NSLS(@"No upcoming bookings", @"");
        [self addSegmentDataSource:upcomingBookingDS];
        
        BookingsWidgetRecentSegment *recentBookingDS = [BookingsWidgetRecentSegment new];
        recentBookingDS.title = NSLS(@"Recently Added", @"");
        recentBookingDS.emptyDataString = NSLS(@"No recently added bookings", @"");
        [self addSegmentDataSource:recentBookingDS];
    }
    return self;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
    }
    return _dateFormatter;
}

- (NSDateIntervalFormatter *)intervalFormatter
{
    if (!_intervalFormatter) {
        _intervalFormatter = [NSDateIntervalFormatter new];
        [_intervalFormatter setTimeStyle:NSDateIntervalFormatterShortStyle];
        [_intervalFormatter setDateStyle:NSDateIntervalFormatterShortStyle];
    }
    return _intervalFormatter;
}

- (UINib *)nibForItemCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if ([reuseIdentifier isEqualToString:kDashboardBookingsWidgetCellReuseIdentifier]) {
        return [UINib nibWithNibName:@"DashboardBookingCollectionViewCell" bundle:nil];
    }
    return [super nibForItemCellWithReuseIdentifier:reuseIdentifier];
}

- (NSString *)reusableIdentifierForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return kDashboardBookingsWidgetCellReuseIdentifier;
}

- (void)configureReusableViewsForCollectionView:(UICollectionView *)collectionView
{
    [collectionView registerNib:[self nibForItemCellWithReuseIdentifier:kDashboardBookingsWidgetCellReuseIdentifier]
     forCellWithReuseIdentifier:kDashboardBookingsWidgetCellReuseIdentifier];
    return [super configureReusableViewsForCollectionView:collectionView];
}

- (void)configureCell:(DashboardBookingCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert([cell isKindOfClass:[DashboardBookingCollectionViewCell class]]);
    SBBooking *booking = [self itemAtIndexPath:indexPath];
    cell.dateTimeLabel.text = [self.intervalFormatter stringFromDate:booking.startDate toDate:booking.endDate];
    cell.bookingDetailsLabel.text = [NSString stringWithFormat:NSLS(@"%@ by %@",@""), booking.eventTitle, booking.performerName];
    cell.performerLabel.text = booking.clientName;
}

- (void)configureView:(UICollectionReusableView *)view forSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:kDashboardErrorMessageSupplementaryKind]) {
        NSAssert([view isKindOfClass:[MessageCollectionReusableView class]], @"%@: MessageCollectionReusableView class expected for supplementary element of kind %@", NSStringFromClass([self class]), kind);
        MessageCollectionReusableView *messageView = (MessageCollectionReusableView *)view;
        BookingsWidgetRecentSegment *segment = (BookingsWidgetRecentSegment *)self.selectedSegment;
        messageView.messageLabel.text = segment.emptyDataString;
    } else {
        [super configureView:view forSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.selectedSegment.items[indexPath.item];
}

@end

@implementation BookingsWidgetRecentSegment

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.filter = [SBGetBookingsFilter new];
        self.filter.order = kSBGetBookingsFilterOrderByRecordDate;
        self.filter.limit = @5;
    }
    return self;
}

- (SBRequest *)dataLoadingRequest
{
    SBRequest *request = [[SBSession defaultSession] getBookingsWithFilter:self.filter callback:^(SBResponse *response) {
        NSIndexSet *toRemove = nil, *toInsert = nil, *toReload = nil;
        NSInteger resultItemsCount = [response.result count];
        if (self.items.count == resultItemsCount) {
            toReload = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.items.count)];
        }
        else if (self.items.count > resultItemsCount) {
            toRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange((resultItemsCount > 0 ? resultItemsCount - 1 : 0), self.items.count)];
            toReload = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, resultItemsCount)];
        }
        else {
            if (self.items.count > 0) {
                toInsert = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.items.count - 1, resultItemsCount)];
                toReload = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.items.count)];
            }
            else {
                toInsert = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, resultItemsCount)];
            }
        }
        self.dataEmpty = (resultItemsCount == 0);
        self.error = response.error;
        self.dataLoaded = (response.error == nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.items = response.result;
            self.loading = NO;
            if (self.parent.selectedSegment == self && self.parent.delegate) {
                if (toInsert && [self.parent.delegate respondsToSelector:@selector(dashboardWidget:didInsertItemsWithIndexes:)]) {
                    [self.parent.delegate dashboardWidget:self.parent didInsertItemsWithIndexes:toInsert];
                }
                if (toRemove && [self.parent.delegate respondsToSelector:@selector(dashboardWidget:didRemoveItemsWithIndexes:)]) {
                    [self.parent.delegate dashboardWidget:self.parent didRemoveItemsWithIndexes:toRemove];
                }
                if (toReload && [self.parent.delegate respondsToSelector:@selector(dashboardWidget:didRefreshItemsAtIndexes:)]) {
                    [self.parent.delegate dashboardWidget:self.parent didRefreshItemsAtIndexes:toReload];
                }
            }
        });
    }];
    return request;
}

@end

@implementation BookingsWidgetUpcomingSegment

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.filter = [SBGetBookingsFilter new];
        self.filter.from = [NSDate date];
        self.filter.to = nil;
        self.filter.order = kSBGetBookingsFilterOrderByStartDateAsc;
        self.filter.upcomingOnly = @YES;
        self.filter.limit = @5;
    }
    return self;
}

@end