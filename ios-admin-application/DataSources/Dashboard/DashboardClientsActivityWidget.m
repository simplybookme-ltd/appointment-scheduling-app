//
//  DashboardClientsActivityWidget.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardClientsActivityWidget.h"
#import "UIColor+SimplyBookColors.h"
#import "SBSession.h"
#import "PieChartCollectionViewCell.h"
#import "XYPieChart.h"
#import "MessageCollectionReusableView.h"

NSString * const kDashboardClientsActivityWidgetCellReuseIdentifier = @"kDashboardClientsActivityWidgetCellReuseIdentifier";

@interface ClientsActivityWidgetBookingsSegment : DashboardSegmentDataSource
@end

@interface ClientsActivityWidgetCancelationsSegment : DashboardSegmentDataSource
@end

@interface DashboardClientsActivityWidget () <XYPieChartDataSource>

@end

@implementation DashboardClientsActivityWidget

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dataUpdateStrategy = [DashboardWidgetUpdateStrategy notificationUpdateStrategyWithNotificationName:UIApplicationSignificantTimeChangeNotification
                                                                                                observingObject:nil
                                                                                                      forWidget:self];
        self.preferredWidgetHeight = 150;
        self.title = NSLS(@"Clients activity", @"");
        self.color = [UIColor colorFromHEXString:@"#ff6c60"];
        
        ClientsActivityWidgetBookingsSegment *activityByBookingsDS = [ClientsActivityWidgetBookingsSegment new];
        activityByBookingsDS.title = NSLS(@"Bookings",@"");
        [self addSegmentDataSource:activityByBookingsDS];
        
        ClientsActivityWidgetCancelationsSegment *activityByCancelationsDS = [ClientsActivityWidgetCancelationsSegment new];
        activityByCancelationsDS.title = NSLS(@"Cancelations",@"");
        [self addSegmentDataSource:activityByCancelationsDS];
    }
    return self;
}

- (UINib *)nibForItemCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if ([reuseIdentifier isEqualToString:kDashboardClientsActivityWidgetCellReuseIdentifier]) {
        return [UINib nibWithNibName:@"PieChartCollectionViewCell" bundle:nil];
    }
    return [super nibForItemCellWithReuseIdentifier:reuseIdentifier];
}

- (NSString *)reusableIdentifierForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return kDashboardClientsActivityWidgetCellReuseIdentifier;
}

- (void)configureReusableViewsForCollectionView:(UICollectionView *)collectionView
{
    [collectionView registerNib:[self nibForItemCellWithReuseIdentifier:kDashboardClientsActivityWidgetCellReuseIdentifier]
       forCellWithReuseIdentifier:kDashboardClientsActivityWidgetCellReuseIdentifier];
    return [super configureReusableViewsForCollectionView:collectionView];
}

- (void)configureCell:(PieChartCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert([cell isKindOfClass:[PieChartCollectionViewCell class]]);
    cell.primaryValueLabel.text = [NSString stringWithFormat:@"%.2f%%", [self.selectedSegment.items[0][@"value"] floatValue]];
    cell.pieChart.dataSource = self;
    [cell.pieChart reloadData];
    for (NSInteger i = 0; i < self.selectedSegment.items.count; i++) {
        NSDictionary *slice = self.selectedSegment.items[i];
        NSString *format = @"%.2f%% %@";
        CGFloat value = [slice[@"value"] floatValue];
        if (value - floor(value) == 0) {
            format = @"%.0f%% %@";
        }
        [cell addValue:slice[@"value"]
             withLabel:[NSString stringWithFormat:format, value, slice[@"label"]]
                 color:[self pieChart:nil colorForSliceAtIndex:i]];
    }
}

- (void)configureView:(UICollectionReusableView *)view forSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:kDashboardErrorMessageSupplementaryKind]) {
        NSAssert([view isKindOfClass:[MessageCollectionReusableView class]], @"%@: MessageCollectionReusableView class expected for supplementary element of kind %@", NSStringFromClass([self class]), kind);
        MessageCollectionReusableView *messageView = (MessageCollectionReusableView *)view;
        messageView.messageLabel.text = NSLS(@"No data available", @"");
    } else {
        [super configureView:view forSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

- (NSUInteger)numberOfItems
{
    if ([self.selectedSegment isLoading] || ![self.selectedSegment isDataLoaded] || [self isDataEmpty]) {
        return 0;
    }
    return 1;
}

#pragma mark -

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart
{
    return self.selectedSegment.items.count;
}

- (NSString *)pieChart:(XYPieChart *)pieChart textForSliceAtIndex:(NSUInteger)index
{
    return @"";
}

- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
            return [UIColor colorWithRed:0.969 green:0.329 blue:0.306 alpha:1.000];
        case 1:
            return [UIColor colorWithRed:0.960 green:0.838 blue:0.247 alpha:1.000];
    }
    return [UIColor colorWithWhite:0.870 alpha:1.000];
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index
{
    return [self.selectedSegment.items[index][@"value"] floatValue];
}

@end

@implementation ClientsActivityWidgetBookingsSegment

- (SBRequest *)dataLoadingRequest
{
    SBRequest *request = [[SBSession defaultSession] getBookingCancellationsInfoForStartDate:nil endDate:nil callback:^(SBResponse *response) {
        BOOL needInsert = (self.items.count == 0);
        if (!response.error) {
            NSUInteger createdByClient	= 0;
            NSUInteger createdByUser = 0;
            for (NSDictionary *data in response.result) {
                if ([data[@"type"] isEqualToString:@"create"]) {
                    if (!data[@"user_id"] || [data[@"user_id"] isEqual:[NSNull null]]) {
                        createdByClient += [data[@"cnt"] integerValue];
                    } else {
                        createdByUser += [data[@"cnt"] integerValue];
                    }
                }
            }
            NSInteger createdTotal = createdByClient + createdByUser;
            self.dataEmpty = (createdTotal == 0);
            self.items = @[
                           @{@"label" : NSLS(@"By clients", @""),
                             @"value" : (createdTotal > 0 ? @(((float)createdByClient / (float)createdTotal) * 100) : @0)},
                           @{@"label" : NSLS(@"By admin/employee", @""),
                             @"value" : (createdTotal > 0 ? @(((float)createdByUser / (float)createdTotal) * 100) : @0)}
                           ];
            self.dataLoaded = YES;
        }
        self.error = response.error;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            if (self.parent.selectedSegment == self && self.parent.delegate) {
                if ([self.parent numberOfItems] != 0) {
                    if (needInsert && [self.parent.delegate respondsToSelector:@selector(dashboardWidget:didInsertItemsWithIndexes:)]) {
                        [self.parent.delegate dashboardWidget:self.parent didInsertItemsWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.parent numberOfItems])]];
                    }
                    else if ([self.parent.delegate respondsToSelector:@selector(dashboardWidget:didRefreshItemsAtIndexes:)]) {
                        [self.parent.delegate dashboardWidget:self.parent didRefreshItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.parent numberOfItems])]];
                    }
                }
                else if ([self.parent.delegate respondsToSelector:@selector(dashboardWidgetDidRefreshWidgetData:)]) {
                    [self.parent.delegate dashboardWidgetDidRefreshWidgetData:self.parent];
                }
            }
        });
    }];
    return request;
}

@end

@implementation ClientsActivityWidgetCancelationsSegment

- (SBRequest *)dataLoadingRequest
{
    SBRequest *request = [[SBSession defaultSession] getBookingCancellationsInfoForStartDate:nil endDate:nil callback:^(SBResponse *response) {
        BOOL needInsert = (self.items.count == 0);
        if (!response.error) {
            NSUInteger canceledByClient = 0;
            NSUInteger canceledByUser = 0;
            NSUInteger canceledBySystem = 0;
            for (NSDictionary <NSString *, NSString *> *data in response.result) {
                if ([data[@"type"] isEqualToString: @"cancel"]) {
                    if (!data[@"user_id"] || [data[@"user_id"] isEqual:[NSNull null]]) {
                        canceledByClient += [data[@"cnt"] integerValue];
                    } else {
                        canceledByUser += [data[@"cnt"] integerValue];
                    }
                }
                else if ([data[@"type"] isEqualToString:@"nopayment_cancel"]) {
                    canceledBySystem += [data[@"cnt"] integerValue];
                }
            }
            NSInteger canceledTotal = canceledByClient + canceledByUser;
            self.dataEmpty = (canceledTotal == 0);
            self.items = @[
                           @{@"label" : NSLS(@"By clients", @""),
                             @"value" : (canceledTotal > 0 ? @(((float)canceledByClient / (float)canceledTotal) * 100) : @0)},
                           @{@"label" : NSLS(@"By admin/employee", @""),
                             @"value" : (canceledTotal > 0 ? @(((float)canceledByUser / (float)canceledTotal) * 100) : @0)},
                           @{@"label" : NSLS(@"System cancellations", @""),
                             @"value" : (canceledTotal > 0 ? @(((float) canceledBySystem / (float) canceledTotal) * 100) : @0)}
                           ];
            self.dataLoaded = YES;
        }
        self.error = response.error;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            if (self.parent.selectedSegment == self && self.parent.delegate) {
                if (needInsert && [self.parent.delegate respondsToSelector:@selector(dashboardWidget:didInsertItemsWithIndexes:)]) {
                    [self.parent.delegate dashboardWidget:self.parent didInsertItemsWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.parent numberOfItems])]];
                }
                else if ([self.parent.delegate respondsToSelector:@selector(dashboardWidget:didRefreshItemsAtIndexes:)]) {
                    [self.parent.delegate dashboardWidget:self.parent didRefreshItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.parent numberOfItems])]];
                }
            }
        });
    }];
    return request;
}

@end