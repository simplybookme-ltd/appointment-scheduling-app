//
//  DashboardViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardViewController.h"
#import "DashboardTitledWidgetDataSource.h"
#import "DashboardSegmentedWidgetDataSource.h"
#import "DashboardCollectionViewLayout.h"
#import "UIColor+SimplyBookColors.h"
#import "CalendarCellDecorationView.h"
#import "ActivityIndicatorCollectionReusableView.h"
#import "DashboardVisitsWidget.h"
#import "DashboardTariffWidget.h"
#import "DashboardBookingsWidget.h"
#import "DashboardTopChartWidget.h"
#import "DashboardClientsActivityWidget.h"
#import "UITraitCollection+SimplyBookLayout.h"
#import "SBBooking.h"
#import "BookingDetailsViewController.h"
#import "SBSessionManager.h"

@interface DashboardViewController ()
<
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    DashboardSegmentedWidgetDataSourceDelegate,
    DashboardCollectionViewLayoutProtocol
>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet DashboardCollectionViewLayout *collectionViewLayout;
@property (nonatomic, strong) NSMutableArray *widgets;

@end

@implementation DashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.125 green:0.157 blue:0.200 alpha:1.000];
    self.collectionViewLayout.dataSource = self;
    self.widgets = [NSMutableArray array];
    
    DashboardBookingsWidget *bookingsWidget = [DashboardBookingsWidget new];
    bookingsWidget.delegate = self;
    [self.widgets addObject:bookingsWidget];
    
    DashboardTariffWidget *tariffInfoWidget = [DashboardTariffWidget new];
    tariffInfoWidget.delegate = self;
    [self.widgets addObject:tariffInfoWidget];
    
    DashboardTopChartWidget *topPerformersAndServicesWidget = [DashboardTopChartWidget new];
    topPerformersAndServicesWidget.delegate = self;
    [self.widgets addObject:topPerformersAndServicesWidget];
    
    DashboardVisitsWidget *visitsWidget = [DashboardVisitsWidget new];
    visitsWidget.delegate = self;
    [self.widgets addObject:visitsWidget];
    
    DashboardClientsActivityWidget *clientsActivityWidget = [DashboardClientsActivityWidget new];
    clientsActivityWidget.delegate = self;
    [self.widgets addObject:clientsActivityWidget];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self.collectionViewLayout registerClass:[CalendarCellDecorationView class]
                     forDecorationViewOfKind:kDashboardWidgetBackgroundDecorationViewKind];
    [self.collectionViewLayout registerClass:[CalendarCellDecorationView class]
                     forDecorationViewOfKind:kDashboardWidgetSeparatorDecorationViewKind];
    [self.collectionView registerNib:[UINib nibWithNibName:@"TextCollectionViewCell" bundle:nil]
          forSupplementaryViewOfKind:kDashboardErrorMessageSupplementaryKind
                 withReuseIdentifier:kDashboardErrorMessageSupplementaryReuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"ActivityIndicatorCollectionReusableView" bundle:nil]
          forSupplementaryViewOfKind:kDashboardLoadingIndicatorSupplementaryKind
                 withReuseIdentifier:kDashboardLoadingIndicatorSupplementaryReuseIdentifier];
    for (DashboardAbstractWidgetDataSource *widget in self.widgets) {
        [widget configureReusableViewsForCollectionView:self.collectionView];
        [widget loadData];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidEndNotificationHandler:)
                                                 name:kSBSessionManagerDidEndSessionNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSBSessionManagerDidEndSessionNotification object:nil];
    for (DashboardAbstractWidgetDataSource *widget in self.widgets) {
        [widget.dataUpdateStrategy cancelUpdates]; // invalidate timers on logout
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray <NSIndexPath *> *)indexPathsForWidget:(DashboardAbstractWidgetDataSource *)widget rowIndexes:(NSIndexSet *)indexes
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSUInteger section = [self.widgets indexOfObject:widget];
    NSAssert(section != NSNotFound, @"unexpected widget");
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}

#pragma mark - Notification handlers

- (void)sessionDidEndNotificationHandler:(NSNotification *)notification
{
    for (DashboardAbstractWidgetDataSource *widget in self.widgets) {
        [widget.dataUpdateStrategy cancelUpdates]; // invalidate timers on logout
    }
}

#pragma mark - Dashboard widget delegate

- (void)dashboardSegmentedWidget:(DashboardSegmentedWidgetDataSource *)widget didSelectSegmentWithIndex:(NSUInteger)selectedSegmentIndex previouslySelectedSegmentIndex:(NSUInteger)previouslySelectedIndex
{
    if (![self.widgets containsObject:widget]) {
        return;
    }
    [self.collectionView performBatchUpdates:^{
        NSUInteger widgetIndex = [self.widgets indexOfObject:widget];
        /// it is possible that UICollectionView have bug. on delete/insert items
        /// in last section app crashes with exception.
        /// @see http://www.openradar.me/12877037
        if (widgetIndex == self.widgets.count - 1) {
            if (![widget isDataLoaded]) {
                [widget loadData];
            }
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:widgetIndex]];
            return ;
        }
        NSMutableArray *toDelete = [NSMutableArray array];
        for (NSUInteger i = 0; i < [[widget.segments[previouslySelectedIndex] items] count]; i++) {
            [toDelete addObject:[NSIndexPath indexPathForItem:i inSection:widgetIndex]];
        }
        if (toDelete.count) {
            [self.collectionView deleteItemsAtIndexPaths:toDelete];
        }
        NSMutableArray *toInsert = [NSMutableArray array];
        for (NSUInteger i = 0; i < [[widget.selectedSegment items] count]; i++) {
            [toInsert addObject:[NSIndexPath indexPathForItem:i inSection:widgetIndex]];
        }
        if (toInsert.count) {
            [self.collectionView insertItemsAtIndexPaths:toInsert];
        }
        if (![widget isDataLoaded]) {
            [widget loadData];
        }
    } completion:^(BOOL finished) {
        
    }];
}

- (void)dashboardWidgetDidStartDataLoading:(DashboardAbstractWidgetDataSource *)widget
{
    [self.collectionView reloadData];
}

- (void)dashboardWidget:(DashboardAbstractWidgetDataSource *)widget didFinishDataLoadingWithResponse:(SBResponse *)response
{
}

- (void)dashboardWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget didRemoveItemsWithIndexes:(NSIndexSet * _Nonnull)indexes
{
    NSArray <NSIndexPath *> *indexPaths = [self indexPathsForWidget:widget rowIndexes:indexes];
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void)dashboardWidgetDidRefreshWidgetData:(DashboardAbstractWidgetDataSource *_Nonnull)widget
{
    NSUInteger section = [self.widgets indexOfObject:widget];
    NSAssert(section != NSNotFound, @"unexpected widget");
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:section]];
}

- (void)dashboardWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget didRefreshItemsAtIndexes:(NSIndexSet *_Nonnull)indexes
{
    NSArray <NSIndexPath *> *indexPaths = [self indexPathsForWidget:widget rowIndexes:indexes];
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

- (void)dashboardWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget didInsertItemsWithIndexes:(NSIndexSet * _Nonnull)indexes
{
    NSArray <NSIndexPath *> *indexPaths = [self indexPathsForWidget:widget rowIndexes:indexes];
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
}

#pragma mark -

- (CGFloat)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout heightForSupplementaryViewOfKind:(NSString *)kind inSection:(NSUInteger)section
{
    DashboardAbstractWidgetDataSource *widget = self.widgets[section];
    UICollectionReusableView *headerView = [widget viewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:nil];
    [widget configureView:headerView forSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:nil];
    CGSize headerSize = [headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return headerSize.height;
}

- (BOOL)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout shouldDisplayErrorMessageInSection:(NSUInteger)section
{
    DashboardAbstractWidgetDataSource *widget = self.widgets[section];
    return widget.error != nil || [widget isDataEmpty];
}

- (BOOL)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout shouldDisplayActivityIndicatorInSection:(NSUInteger)section
{
    DashboardAbstractWidgetDataSource *widget = self.widgets[section];
    return [widget isLoading];
}

- (DashboardCollectionViewLayoutSectionDirection)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout directionForSection:(NSUInteger)section
{
    DashboardAbstractWidgetDataSource *widget = self.widgets[section];
    if ([widget isKindOfClass:[DashboardTariffWidget class]] || [widget isKindOfClass:[DashboardVisitsWidget class]]) {
        return DashboardCollectionViewLayoutHorizontalSectionDirection;
    }
    return DashboardCollectionViewLayoutVerticalSectionDirection;
}

- (CGFloat)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout heightForCellForItemAtIndexPath:(NSIndexPath *)indexPath maxWidth:(CGFloat)maxWidth
{
    DashboardAbstractWidgetDataSource *widget = self.widgets[indexPath.section];
    return widget.preferredWidgetHeight;
}

- (DashboardCollectionViewLayoutWidgetLayout)dashboardViewLayout:(DashboardCollectionViewLayout *)dashboardLayout widgetLayoutForSection:(NSUInteger)section
{
    if ([self.traitCollection isWideLayout]) {
        DashboardAbstractWidgetDataSource *widget = self.widgets[section];
        if (![widget isKindOfClass:[DashboardBookingsWidget class]]) {
            return DashboardCollectionViewLayoutHalfWidthWidgetLayout;
        }
    }
    return DashboardCollectionViewLayoutFullWidthWidgetLayout;
}

#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.widgets.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    DashboardAbstractWidgetDataSource *widget = self.widgets[section];
    return [widget numberOfItems];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DashboardAbstractWidgetDataSource *widget = self.widgets[indexPath.section];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[widget reusableIdentifierForItemAtIndexPath:indexPath]
                                                                           forIndexPath:indexPath];
    [widget configureCell:cell forItemAtIndexPath:indexPath];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    DashboardAbstractWidgetDataSource *widget = self.widgets[indexPath.section];
    UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                              withReuseIdentifier:[widget reusableIdentifierForSupplementaryViewOnKind:kind]
                                                                                     forIndexPath:indexPath];
    [widget configureView:headerView forSupplementaryElementOfKind:kind atIndexPath:indexPath];
    return headerView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DashboardAbstractWidgetDataSource *widget = self.widgets[indexPath.section];
    if ([widget isKindOfClass:[DashboardBookingsWidget class]]) {
        NSLog(@"click");
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self performSegueWithIdentifier:@"showBookingDetails-iPad" sender:self];
        }
        else {
            [self performSegueWithIdentifier:@"showBookingDetails" sender:self];
        }
    }
}

#pragma mark -

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"showBookingDetails"]
             || [identifier isEqualToString:@"showBookingDetails-iPad"])
    {
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        if (!indexPath) {
            return NO;
        }
        DashboardAbstractWidgetDataSource *widget = self.widgets[indexPath.section];
        if (![widget isKindOfClass:[DashboardBookingsWidget class]]) {
            return NO;
        }
        SBBooking *booking = (SBBooking *)[widget itemAtIndexPath:indexPath];
        if (!booking) {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
            return NO;
        }
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showBookingDetails"]
             || [segue.identifier isEqualToString:@"showBookingDetails-iPad"])
    {
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        NSAssert(indexPath != nil, @"no selected bookings");
        DashboardAbstractWidgetDataSource *widget = self.widgets[indexPath.section];
        SBBooking *booking = (SBBooking *)[widget itemAtIndexPath:indexPath];
        BookingDetailsViewController *controller = nil;
        if ([segue.identifier isEqualToString:@"showBookingDetails"]) {
            controller = segue.destinationViewController;
        }
        else if ([segue.identifier isEqualToString:@"showBookingDetails-iPad"]) {
            NSAssert([segue.destinationViewController isKindOfClass:[UINavigationController class]], @"unexpected view controllers hierarchy");
            controller = (BookingDetailsViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
        }
        controller.bookingID = booking.bookingID;
        controller.clientName = booking.clientName;
        controller.clientEmail = booking.clientEmail;
        controller.clientPhone = booking.clientPhone;
        controller.onBookingCanceledHandler = ^(NSString *bookingID) {
            [widget loadData];
        };
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}

@end
