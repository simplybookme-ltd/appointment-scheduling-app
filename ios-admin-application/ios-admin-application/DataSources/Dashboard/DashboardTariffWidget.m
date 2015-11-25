//
//  DashboardTariffWidgetDataSource.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardTariffWidget.h"
#import "DashboardAbstractWidgetDataSource_Private.h"
#import "SBSession.h"
#import "VerticalKeyValueCollectionViewCell.h"
#import "UIColor+SimplyBookColors.h"
#import "MessageCollectionReusableView.h"
#import "NSDateFormatter+ServerParser.h"

NS_ENUM(NSInteger, TariffWidgetRows)
{
    TariffWidgetDaysLeftRow,
    TariffWidgetSMSCreditsRow,
    TariffWidgetBookingsLeftRow,
    TariffWidgetPluginUserdRow,
    TariffWidgetRowsCount
};

NSString *const kDashboardTariffWidgetCellReuseIdentifier = @"kDashboardTariffWidgetCellReuseIdentifier";

@interface DashboardTariffWidget ()
{
    NSString *requestGUID;
    NSDate *tariffExpirationDate;
    NSUInteger daysLeft;
    NSUInteger smsCredits;
    NSUInteger bookingsLeft;
    NSUInteger pluginsUsed;
}

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@end

@implementation DashboardTariffWidget

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dataUpdateStrategy = [DashboardWidgetUpdateStrategy notificationUpdateStrategyWithNotificationName:UIApplicationSignificantTimeChangeNotification
                                                                                                observingObject:nil
                                                                                                      forWidget:self];
        self.preferredWidgetHeight = 170.;
        self.title = [NSString stringWithFormat:NSLS(@"Your current tariff: %@", @""), @"--"];
        self.subtitle = [NSString stringWithFormat:NSLS(@"valid until: %@", @""), @"--"];
        self.color = [UIColor colorFromHEXString:@"#c0c0c0"]; // color later will be loaded from server
    }
    return self;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    return _dateFormatter;
}

- (NSNumberFormatter *)numberFormatter
{
    if (!_numberFormatter) {
        _numberFormatter = [NSNumberFormatter new];
        [_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    }
    return _numberFormatter;
}

- (UINib *)nibForItemCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if ([reuseIdentifier isEqualToString:kDashboardTariffWidgetCellReuseIdentifier]) {
        return [UINib nibWithNibName:@"VerticalKeyValueCollectionViewCell" bundle:nil];
    }
    return [super nibForItemCellWithReuseIdentifier:reuseIdentifier];
}

- (NSString *)reusableIdentifierForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return kDashboardTariffWidgetCellReuseIdentifier;
}

- (void)configureReusableViewsForCollectionView:(UICollectionView *)collectionView
{
    [collectionView registerNib:[self nibForItemCellWithReuseIdentifier:kDashboardTariffWidgetCellReuseIdentifier]
     forCellWithReuseIdentifier:kDashboardTariffWidgetCellReuseIdentifier];
    return [super configureReusableViewsForCollectionView:collectionView];
}

- (NSNumber *)numberFromValue:(id)value
{
    if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    else if ([value isKindOfClass:[NSString class]]) {
        return [self.numberFormatter numberFromString:value];
    }
    return nil;
}

- (SBRequest *)dataLoadingRequest
{
    SBRequest *request = [[SBSession defaultSession] getCurrentTariffInfo:^(SBResponse *response) {
        if (response.error) {
            self.error = response.error;
        }
        else {
            self.dataLoaded = YES;
            NSDictionary *tariffInfo = response.result;
            if (tariffInfo[@"color"] && ![tariffInfo[@"color"] isEqual:[NSNull null]]) {
                self.color = [UIColor colorFromHEXString:tariffInfo[@"color"]];
            }
            if ([tariffInfo[@"name"] isEqual:[NSNull null]]) {
                self.title = NSLS(@"Your current tariff",@"");
                self.subtitle = NSLS(@"Expired", @"");
            }
            else {
                self.title = [NSString stringWithFormat:NSLS(@"Your current tariff is: %@", @""), tariffInfo[@"name"]];
                tariffExpirationDate = [[NSDateFormatter sb_serverDateFormatter] dateFromString:tariffInfo[@"expire_date"]];
                self.subtitle = [NSString stringWithFormat:NSLS(@"valid until: %@", @""), [self.dateFormatter stringFromDate:tariffExpirationDate]];
            }

            NSNumber *number = [self numberFromValue:tariffInfo[@"rest"][@"sheduler_limit"]];
            bookingsLeft = (number.floatValue < 0) ? NSUIntegerMax : number.integerValue;
            number = [self numberFromValue:tariffInfo[@"rest"][@"sms_limit"]];
            smsCredits = (number.floatValue < 0) ? NSUIntegerMax : number.integerValue;
            number = [self numberFromValue:tariffInfo[@"rest"][@"days"]];
            daysLeft = (number.floatValue < 0) ? 0 : number.integerValue; // if negative then subscription expired which means 0 days left
            number = [self numberFromValue:tariffInfo[@"rest"][@"plugins_limit"]];
            pluginsUsed = (number.floatValue < 0) ? NSUIntegerMax : number.integerValue;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(dashboardWidgetDidRefreshWidgetData:)]) {
                [self.delegate dashboardWidgetDidRefreshWidgetData:self];
            }
        });
    }];
    requestGUID = request.GUID;
    return request;
}

- (NSUInteger)numberOfItems
{
    if ([self isLoading] || ![self isDataLoaded] || [self isDataEmpty]) {
        return 0;
    }
    return TariffWidgetRowsCount;
}

- (void)configureCell:(VerticalKeyValueCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert([cell isKindOfClass:[VerticalKeyValueCollectionViewCell class]], @"Unexpected cell class");
    cell.keyLabel.font = [UIFont systemFontOfSize:12.];
    cell.keyLabel.textColor = [UIColor colorFromHEXString:@"#74829c"];
    cell.valueLabel.font = [UIFont systemFontOfSize:22.];
    cell.valueLabel.textColor = [UIColor colorFromHEXString:@"#74829c"];
    cell.imageView.tintColor = self.color;
    switch (indexPath.item) {
        case TariffWidgetDaysLeftRow:
            cell.imageView.image = [UIImage imageNamed:@"dashboard-tariff-widget-days"];
            cell.keyLabel.text = NSLS(@"Days Left", @"");
            cell.valueLabel.text = (daysLeft == NSUIntegerMax ? @"∞" : [NSString stringWithFormat:@"%ld", (long)daysLeft]);
            break;
        case TariffWidgetSMSCreditsRow:
            cell.imageView.image = [UIImage imageNamed:@"dashboard-tariff-widget-sms"];
            cell.keyLabel.text = NSLS(@"SMS Credit", @"");
            cell.valueLabel.text = (smsCredits == NSUIntegerMax ? @"∞" : [NSString stringWithFormat:@"%ld", (long)smsCredits]);
            break;
        case TariffWidgetBookingsLeftRow:
            cell.imageView.image = [UIImage imageNamed:@"dashboard-tariff-widget-bookings"];
            cell.keyLabel.text = NSLS(@"Bookings Left", @"");
            cell.valueLabel.text = (bookingsLeft == NSUIntegerMax ? @"∞" : [NSString stringWithFormat:@"%ld", (long)bookingsLeft]);
            break;
        case TariffWidgetPluginUserdRow:
            cell.imageView.image = [UIImage imageNamed:@"dashboard-tariff-widget-plugins"];
            cell.keyLabel.text = NSLS(@"Plugins Used", @"");
            cell.valueLabel.text = (pluginsUsed == NSUIntegerMax ? @"∞" : [NSString stringWithFormat:@"%ld", (long)pluginsUsed]);
            break;
            
        default:
            break;
    }
}

- (void)configureView:(UICollectionReusableView *)view forSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:kDashboardErrorMessageSupplementaryKind]) {
        NSAssert([view isKindOfClass:[MessageCollectionReusableView class]], @"%@: MessageCollectionReusableView class expected for supplementary element of kind %@", NSStringFromClass([self class]), kind);
        MessageCollectionReusableView *messageView = (MessageCollectionReusableView *)view;
        messageView.messageLabel.text = NSLS(@"No data available", @"");
    }
    else {
        return [super configureView:view forSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

@end
