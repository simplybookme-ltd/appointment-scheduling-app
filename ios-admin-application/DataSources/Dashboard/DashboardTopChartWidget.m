//
//  DashboardTopChartWidget.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardTopChartWidget.h"
#import "UIColor+SimplyBookColors.h"
#import "SBSession.h"
#import "HorizontalKeyValueCollectionViewCell.h"
#import "SBRequestsGroup.h"
#import "SBGetWorkloadRequest.h"
#import "MessageCollectionReusableView.h"

NSString * const kDashboardTopChartWidgetCellReuseIdentifier = @"kDashboardTopChartWidgetCellReuseIdentifier";

@interface TopChartWidgetTopPerformerSegment : DashboardSegmentDataSource
{
    NSDictionary *data;
    CGFloat workingHours;
    CGFloat workload;
}

@property (nonatomic, strong) NSString *currencyCode;

@end

@interface TopChartWidgetTopServiceSegment : TopChartWidgetTopPerformerSegment

@end

@interface DashboardTopChartWidget ()

@property (nonatomic, strong) NSNumberFormatter *moneyFormatter;

@end

@implementation DashboardTopChartWidget

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dataUpdateStrategy = [DashboardWidgetUpdateStrategy notificationUpdateStrategyWithNotificationName:UIApplicationSignificantTimeChangeNotification
                                                                                                observingObject:nil
                                                                                                      forWidget:self];
        self.preferredWidgetHeight = 44;
        self.color = [UIColor colorFromHEXString:@"#41cac0"];
        
        DashboardSegmentDataSource *topPerformersSectionDS = [TopChartWidgetTopPerformerSegment new];
        topPerformersSectionDS.title = NSLS(@"Top Performers",@"");
        [self addSegmentDataSource:topPerformersSectionDS];
        
        DashboardSegmentDataSource *topServicesSectionDS = [TopChartWidgetTopServiceSegment new];
        topServicesSectionDS.title = NSLS(@"Top Services",@"");
        [self addSegmentDataSource:topServicesSectionDS];
    }
    return self;
}

- (NSNumberFormatter *)moneyFormatter
{
    if (!_moneyFormatter) {
        _moneyFormatter = [NSNumberFormatter new];
        [_moneyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    }
    return _moneyFormatter;
}

- (UINib *)nibForItemCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if ([reuseIdentifier isEqualToString:kDashboardTopChartWidgetCellReuseIdentifier]) {
        return [UINib nibWithNibName:@"HorizontalKeyValueCollectionViewCell" bundle:nil];
    }
    return [super nibForItemCellWithReuseIdentifier:reuseIdentifier];
}

- (NSString *)reusableIdentifierForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return kDashboardTopChartWidgetCellReuseIdentifier;
}

- (void)configureReusableViewsForCollectionView:(UICollectionView *)collectionView
{
    [collectionView registerNib:[self nibForItemCellWithReuseIdentifier:kDashboardTopChartWidgetCellReuseIdentifier]
     forCellWithReuseIdentifier:kDashboardTopChartWidgetCellReuseIdentifier];
    return [super configureReusableViewsForCollectionView:collectionView];
}

- (void)configureCell:(HorizontalKeyValueCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert([cell isKindOfClass:[HorizontalKeyValueCollectionViewCell class]]);
    NSDictionary *item = self.selectedSegment.items[indexPath.item];
    cell.keyLabel.text = item[@"key"];
    cell.keyLabel.textColor = [UIColor colorFromHEXString:@"#74829c"];
    if ([item[@"money"] boolValue]) {
        TopChartWidgetTopPerformerSegment *segment = (TopChartWidgetTopPerformerSegment *)self.selectedSegment;
        /// it is possible that performer|service have payments in different currencies
        if ([segment.currencyCode containsString:@","]) { 
            [self.moneyFormatter setCurrencySymbol:segment.currencyCode];
        }
        else {
            [self.moneyFormatter setCurrencySymbol:nil];
        }
        cell.valueLabel.text = [self.moneyFormatter stringFromNumber:item[@"value"]];
    }
    else {
        cell.valueLabel.text = item[@"value"];
    }
    cell.valueLabel.textColor = [UIColor colorFromHEXString:@"#74829c"];
    cell.imageView.tintColor = self.color;
    if (item[@"icon"]) {
        [cell setImage:[UIImage imageNamed:item[@"icon"]]];
    }
    else {
        [cell setImage:nil];
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

@end

@implementation TopChartWidgetTopServiceSegment

- (SBRequest *)dataLoadingRequest
{
    SBRequest *request = [[SBSession defaultSession] getTopServices:^(SBResponse *response) {
        self.error = response.error;
        if (!response.error) {
            BOOL needsReload = (self.items && self.items.count != 0);
            data = [response.result firstObject];
            self.dataLoaded = YES;
            
            self.currencyCode = data[@"currency"];
            self.items = @[
                           @{
                               @"key" : data[@"name"]
                               },
                           @{
                               @"key" : NSLS(@"Number of bookings",@""),
                               @"value" : data[@"bookings"] ? data[@"bookings"] : @(0),
                               @"icon" : @"dashboard-topchart-widget-bookings"
                               },
                           @{
                               @"key" : NSLS(@"Total revenues",@""),
                               @"value" : data[@"revenue"] ? @([data[@"revenue"] floatValue]) : @(0.0),
                               @"icon" : @"dashboard-topchart-widget-money",
                               @"money" : @YES
                               }
                           ];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.loading = NO;
                if (self.parent.selectedSegment == self) {
                    if (needsReload && [self.parent.delegate respondsToSelector:@selector(dashboardWidget:didRefreshItemsAtIndexes:)]) {
                        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.items.count)];
                        [self.parent.delegate dashboardWidget:self.parent didRefreshItemsAtIndexes:indexes];
                    }
                    else if (!needsReload && [self.parent.delegate respondsToSelector:@selector(dashboardWidget:didInsertItemsWithIndexes:)]) {
                        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.items.count)];
                        [self.parent.delegate dashboardWidget:self.parent didInsertItemsWithIndexes:indexes];
                    }
                }
            });
        }
    }];
    return request;
}

@end

@implementation TopChartWidgetTopPerformerSegment

- (SBRequest *)dataLoadingRequest
{
    __block NSString *performerID = nil;
    __block BOOL needsReload = (self.items && self.items.count != 0);
    SBRequestsGroup *group = [SBRequestsGroup new];
    
    SBRequest *topPerformersRequest = [[SBSession defaultSession] getTopPerformers:^(SBResponse *response) {
        self.error = response.error;
        if (!response.error) {
            data = [response.result firstObject];
            self.currencyCode = data[@"currency"];
            performerID = data[@"id"];
            
        }
    }];
    
    SBRequest *workloadRequest = [[SBSession defaultSession] getWorkloadForStartDate:nil endDate:nil performerID:@"" callback:^(SBResponse *response) {
        self.error = response.error;
        if (!response.error) {
            const NSInteger workIndex = 0;
            const NSInteger loadIndex = 1;
            CGFloat work = 0;
            CGFloat load = 0;
            for (NSDictionary *workloadForDay in [response.result allValues]) {
                if (workloadForDay[performerID] && [workloadForDay[performerID] isKindOfClass:[NSArray class]] && [workloadForDay[performerID] count] > loadIndex) {
                    if (![workloadForDay[performerID][workIndex] isEqual:[NSNull null]]) {
                        work += [workloadForDay[performerID][workIndex] floatValue];
                    }
                    if (![workloadForDay[performerID][loadIndex] isEqual:[NSNull null]]) {
                        load += [workloadForDay[performerID][loadIndex] floatValue];
                    }
                }
            }
            workingHours = work / 60.;
            workload = (load / work) * 100;
            
            NSMutableArray *items = [NSMutableArray array];
            [items addObject:@{
                               @"key" : (data[@"name"] && ![data[@"name"] isEqual:[NSNull null]] ? data[@"name"] : @"")
                               }];
            if (data[@"phone"] && ![data[@"phone"] isEqual:[NSNull null]] && ![data[@"phone"] isEqualToString:@""]) {
                [items addObject:@{
                                   @"key" : data[@"phone"],
                                   @"icon" : @"dashboard-topchart-widget-phone"
                                   }];
            }
            if (data[@"email"] && ![data[@"email"] isEqual:[NSNull null]] && ![data[@"email"] isEqualToString:@""]) {
                [items addObject:@{
                                   @"key" : data[@"email"],
                                   @"icon" : @"dashboard-topchart-widget-email"
                                   }];
            }
            [items addObject:@{
                               @"key" : NSLS(@"Working hours last week",@""),
                               @"value" : [NSString stringWithFormat:@"%.0f %@", workingHours, NSLS(@"h",@"")],
                               @"icon" : @"dashboard-topchart-widget-hours"
                               }];
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterPercentStyle];
            [formatter setMaximumFractionDigits:2];
            [formatter setMultiplier:@1];
            [items addObject:@{
                               @"key" : NSLS(@"Occupancy percentage",@""),
                               @"value" : (work == 0 ? @"--" : [formatter stringFromNumber:@(workload)]),
                               @"icon" : @"dashboard-topchart-widget-workload"
                               }];
            [items addObject:@{
                               @"key" : NSLS(@"Number of bookings",@""),
                               @"value" : data[@"bookings"] ? data[@"bookings"] : @(0),
                               @"icon" : @"dashboard-topchart-widget-bookings"
                               }];
            [items addObject:@{
                               @"key" : NSLS(@"Total revenues",@""),
                               @"value" : data[@"revenue"] ? @([data[@"revenue"] floatValue]) : @(0.0),
                               @"icon" : @"dashboard-topchart-widget-money",
                               @"money" : @YES
                               }];
            self.items = items;
            self.dataLoaded = YES;
        }
    }];
    /**
     * chained request: before get workload we need to get performer data
     */
    workloadRequest.predispatchBlock = ^(SBRequest *r) {
        NSAssert(performerID != nil, @"performer data not loaded");
        SBGetWorkloadRequest *request = (SBGetWorkloadRequest *)r;
        request.performerID = performerID;
    };
    
    [group addRequest:topPerformersRequest];
    [group addRequest:workloadRequest];
    [workloadRequest addDependency:topPerformersRequest];
    
    group.callback = ^(SBResponse *response) {
        self.error = response.error;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            if (self.parent.selectedSegment == self) {
                if (needsReload && [self.parent.delegate respondsToSelector:@selector(dashboardWidget:didRefreshItemsAtIndexes:)]) {
                    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.parent numberOfItems])];
                    [self.parent.delegate dashboardWidget:self.parent didRefreshItemsAtIndexes:indexes];
                }
                else if (!needsReload && [self.parent.delegate respondsToSelector:@selector(dashboardWidget:didInsertItemsWithIndexes:)]) {
                    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.parent numberOfItems])];
                    [self.parent.delegate dashboardWidget:self.parent didInsertItemsWithIndexes:indexes];
                }
            }
        });
    };
    
    return group;
}

@end
