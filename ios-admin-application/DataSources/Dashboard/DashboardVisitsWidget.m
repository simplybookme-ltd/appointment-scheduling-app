//
//  DashboardVisitsWidget.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardVisitsWidget.h"
#import "KeyValueWidgetHeaderCollectionReusableView.h"
#import "SBSession.h"
#import "DashboardAbstractWidgetDataSource_Private.h"
#import "VerticalKeyValueCollectionViewCell.h"
#import "SBRequestsGroup.h"
#import "UIColor+SimplyBookColors.h"
#import "MessageCollectionReusableView.h"
#import "DashboardAbstractWidgetDataSource_Private.h"

NSString * const kDashboardVisitsWidgetHeaderSupplementaryKind = @"kDashboardVisitsWidgetHeaderSupplementaryKind";
NSString * const kDashboardVisitsWidgetHeaderSupplementaryReuseIdentifier = @"kDashboardVisitsWidgetHeaderSupplementaryReuseIdentifier";
NSString * const kDashboardVisitsWidgetCellReuseIdentifier = @"kDashboardVisitsWidgetCellReuseIdentifier";

NS_ENUM(NSUInteger, DashboardVisitsWidgetRows)
{
    DashboardVisitsWidgetVisitsGrowRow,
    DashboardVisitsWidgetBookingsPerVisitRow,
    DashboardVisitsWidgetBookingsPerVisitsGrowRow,
    DashboardVisitsWidgetRowsCount
};

@interface DashboardVisitsWidget ()
{
    CGFloat visitsGrow;
    CGFloat lastWeekVisits;
    CGFloat prevWeekVisits;
//    CGFloat lastWeekBookings;
//    CGFloat prevWeekBookings;
    CGFloat bookingsToVisits;
    CGFloat bookingsToVisitsGrow;
    NSInteger bookingsCreatedByClientLastWeek;
    NSInteger bookingsCreatedByClientPrevWeek;
    NSString *requestGUID;
    NSInteger currentWeekNumber;
}

@property (nonatomic, readonly) NSInteger currentWeekNumber;
@property (nonatomic, strong) NSCalendar *calendar;

@end

@implementation DashboardVisitsWidget

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dataUpdateStrategy = [DashboardWidgetUpdateStrategy notificationUpdateStrategyWithNotificationName:UIApplicationSignificantTimeChangeNotification
                                                                                                observingObject:nil
                                                                                                      forWidget:self];
        currentWeekNumber = -1;
        self.preferredWidgetHeight = 120;
        self.title = NSLS(@"Visits last week", @"");
        self.color = [UIColor colorFromHEXString:@"#8175c7"];
    }
    return self;
}

- (NSInteger)currentWeekNumber
{
    if (currentWeekNumber == -1) {
        currentWeekNumber = [self.calendar component:NSCalendarUnitWeekOfYear fromDate:[NSDate date]];
    }
    return currentWeekNumber;
}

- (NSCalendar *)calendar
{
    if (!_calendar) {
        _calendar = [NSCalendar currentCalendar];
    }
    return _calendar;
}

- (UINib *)nibForViewForSupplementaryElementOfKind:(NSString *_Nonnull)kind
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [UINib nibWithNibName:@"KeyValueWidgetHeaderCollectionReusableView" bundle:nil];
    }
    return [super nibForViewForSupplementaryElementOfKind:kind];
}

- (UINib *)nibForItemCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if ([reuseIdentifier isEqualToString:kDashboardVisitsWidgetCellReuseIdentifier]) {
        return [UINib nibWithNibName:@"VerticalKeyValueCollectionViewCell" bundle:nil];
    }
    return [super nibForItemCellWithReuseIdentifier:reuseIdentifier];
}

- (NSString *)reusableIdentifierForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return kDashboardVisitsWidgetCellReuseIdentifier;
}

- (void)configureReusableViewsForCollectionView:(UICollectionView *)collectionView
{
    [collectionView registerNib:[self nibForItemCellWithReuseIdentifier:kDashboardVisitsWidgetCellReuseIdentifier]
     forCellWithReuseIdentifier:kDashboardVisitsWidgetCellReuseIdentifier];
    [collectionView registerNib:[self nibForViewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader]
     forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
            withReuseIdentifier:kDashboardVisitsWidgetHeaderSupplementaryReuseIdentifier];
    return [super configureReusableViewsForCollectionView:collectionView];
}

- (UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UINib *nib = [self nibForViewForSupplementaryElementOfKind:kind];
        return [[nib instantiateWithOwner:self options:nil] firstObject];
    }
    return [super viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

- (NSString *)reusableIdentifierForSupplementaryViewOnKind:(NSString *)kind
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return kDashboardVisitsWidgetHeaderSupplementaryReuseIdentifier;
    }
    return [super reusableIdentifierForSupplementaryViewOnKind:kind];
}

- (void)configureView:(UICollectionReusableView *)view forSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        NSAssert([view isKindOfClass:[KeyValueWidgetHeaderCollectionReusableView class]], @"%@: KeyValueWidgetHeaderCollectionReusableView class expected for supplementary element of kind %@", NSStringFromClass([self class]), kind);
        KeyValueWidgetHeaderCollectionReusableView *header = (KeyValueWidgetHeaderCollectionReusableView *)view;
        header.backgroundColor = self.color;
        header.keyLabel.text = self.title;
        header.valueLabel.text = (self.dataLoaded ? [NSString stringWithFormat:@"%ld", (long)lastWeekVisits] : @"");
        header.imageView.image = [UIImage imageNamed:@"visits"];
    }
    else if ([kind isEqualToString:kDashboardErrorMessageSupplementaryKind]) {
        NSAssert([view isKindOfClass:[MessageCollectionReusableView class]], @"%@: MessageCollectionReusableView class expected for supplementary element of kind %@", NSStringFromClass([self class]), kind);
        MessageCollectionReusableView *messageView = (MessageCollectionReusableView *)view;
        messageView.messageLabel.text = NSLS(@"No data available", @"");
    } else {
        [super configureView:view forSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

- (SBRequest *)dataLoadingRequest
{
    SBRequestsGroup *group = [SBRequestsGroup new];
    
    SBRequest *checkPluginRequest = [[SBSession defaultSession] isPluginActivated:@"counter" callback:^(SBResponse *response) {
        if (!response.error) {
            if ([response.result boolValue] == NO) {
                self.dataEmpty = YES;
                self.loading = NO;
                [group cancel];
            }
        }
    }];
    [group addRequest:checkPluginRequest];
    
    SBRequest *visitsStatRequest = [[SBSession defaultSession] getVisitorStats:^(SBResponse *response) {
        if (!response.error) {
            NSString *lastWeekVisitsString = response.result[[NSString stringWithFormat:@"%ld", (long)(self.currentWeekNumber - 1)]];
            lastWeekVisits = (lastWeekVisitsString ? [lastWeekVisitsString floatValue] : 0);
            
            NSString *prevWeekVisitsString = response.result[[NSString stringWithFormat:@"%ld", (long)(self.currentWeekNumber - 2)]];
            prevWeekVisits = (prevWeekVisitsString ? [prevWeekVisitsString floatValue] : 0);
        }
    }];
    [group addRequest:visitsStatRequest];
    
    NSInteger currentWeekday = [self.calendar component:NSCalendarUnitWeekday fromDate:[NSDate date]];
    NSDateComponents *components = [NSDateComponents new];
    if (currentWeekday == 1) { // sunday
        components.day = -7;
    }
    else {
        components.day = 0 - (currentWeekday - 1);
    }
    NSDate *lastWeekSunday = [self.calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    components.day = -6;
    NSDate *lastWeekMonday = [self.calendar dateByAddingComponents:components toDate:lastWeekSunday options:0];
    
    SBRequest *bookingsLastWeekStatRequest = [[SBSession defaultSession] getBookingCancellationsInfoForStartDate:lastWeekMonday
                                                                                                         endDate:lastWeekSunday
                                                                                                        callback:^(SBResponse *response)
    {
        if (!response.error) {
            for (NSDictionary *data in response.result) {
                if ([data[@"type"] isEqualToString:@"create"] && (!data[@"user_id"] || [data[@"user_id"] isEqual:[NSNull null]])) {
                    bookingsCreatedByClientLastWeek += [data[@"cnt"] integerValue];
                }
            }
        }
    }];
    [group addRequest:bookingsLastWeekStatRequest];
    
    components.day = -7;
    NSDate *prevWeekSunday = [self.calendar dateByAddingComponents:components toDate:lastWeekSunday options:0];
    NSDate *prevWeekMonday = [self.calendar dateByAddingComponents:components toDate:lastWeekMonday options:0];
    
    SBRequest *bookingsPrevWeekStatRequest = [[SBSession defaultSession] getBookingCancellationsInfoForStartDate:prevWeekMonday
                                                                                                         endDate:prevWeekSunday
                                                                                                        callback:^(SBResponse *response)
    {
        if (!response.error) {
            for (NSDictionary *data in response.result) {
                if ([data[@"type"] isEqualToString:@"create"] && (!data[@"user_id"] || [data[@"user_id"] isEqual:[NSNull null]])) {
                    bookingsCreatedByClientPrevWeek += [data[@"cnt"] integerValue];
                }
            }
        }
    }];
    [group addRequest:bookingsPrevWeekStatRequest];
    
    requestGUID = group.GUID;
    group.callback = ^(SBResponse *response) {
        requestGUID = nil;
        self.dataLoaded = YES;
        
        if (!response.error) {
            visitsGrow = lastWeekVisits * 100.;
            if (prevWeekVisits > 0) {
                visitsGrow = (lastWeekVisits - prevWeekVisits) / prevWeekVisits * 100.;
            }
            
            bookingsToVisits = bookingsCreatedByClientLastWeek;
            if (lastWeekVisits > 0) {
                bookingsToVisits = bookingsCreatedByClientLastWeek / lastWeekVisits;
            }
            
            CGFloat prevBookingsToVisits = bookingsCreatedByClientPrevWeek;
            if (prevWeekVisits > 0) {
                prevBookingsToVisits = bookingsCreatedByClientPrevWeek / prevWeekVisits;
            }
            
            bookingsToVisitsGrow = bookingsToVisits * 100;
            if (prevBookingsToVisits > 0) {
                bookingsToVisitsGrow = (bookingsToVisits - prevBookingsToVisits) / prevBookingsToVisits * 100.;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(dashboardWidgetDidRefreshWidgetData:)]) {
                [self.delegate dashboardWidgetDidRefreshWidgetData:self];
            }
        });

    };
    
    return group;
}

- (NSUInteger)numberOfItems
{
    if ([self isLoading] || ![self isDataLoaded] || [self isDataEmpty]) {
        return 0;
    }
    return DashboardVisitsWidgetRowsCount;
}

- (void)configureCell:(VerticalKeyValueCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert([cell isKindOfClass:[VerticalKeyValueCollectionViewCell class]]);
    cell.valueLabel.numberOfLines = 2;
    cell.keyLabel.font = [UIFont systemFontOfSize:22.];
    cell.keyLabel.textColor = [UIColor colorFromHEXString:@"#74829c"];
    [cell.keyLabel setContentHuggingPriority:[cell.valueLabel contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical] + 1
                                     forAxis:UILayoutConstraintAxisVertical];
    cell.valueLabel.font = [UIFont systemFontOfSize:12.];
    cell.valueLabel.textColor = [UIColor colorFromHEXString:@"#74829c"];
    [cell setImage:nil];
    switch (indexPath.row) {
        case DashboardVisitsWidgetVisitsGrowRow:
            cell.keyLabel.text = [NSString stringWithFormat:@"%.0f%%", visitsGrow];
            cell.valueLabel.text = NSLS(@"Visits grow",@"");
            break;
        case DashboardVisitsWidgetBookingsPerVisitRow:
            cell.keyLabel.text = [NSString stringWithFormat:@"%.2f", bookingsToVisits];
            cell.valueLabel.text = NSLS(@"Bookings per visit",@"");
            break;
        case DashboardVisitsWidgetBookingsPerVisitsGrowRow:
            cell.keyLabel.text = [NSString stringWithFormat:@"%.0f%%", bookingsToVisitsGrow];
            cell.valueLabel.text = NSLS(@"Bookings per visit grow",@"");
            break;
            
        default:
            break;
    }
}

@end
