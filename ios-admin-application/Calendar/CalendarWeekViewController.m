//
//  CalendarWeekViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarWeekViewController.h"
#import "SBGetBookingsFilter.h"
#import "BookingsListViewController.h"
#import "CalendarSectionDataSource.h"
#import "AddBookingViewController.h"
#import "CalendarGridCollectionViewLayout.h"
#import "SBSession.h"
#import "NSError+SimplyBook.h"
#import "BookingDetailsViewController.h"
#import "NSDate+TimeManipulation.h"
#import "SBCompanyInfo.h"
#import "SBWorkingHoursMatrix.h"
#import "NSDateFormatter+ServerParser.h"
#import "UIColor+SimplyBookColors.h"
#import "SBNewBookingPlaceholder.h"
#import "UITraitCollection+SimplyBookLayout.h"
#import "SBPluginsRepository.h"
#import "SBGetBookingsRequest.h"
#import "SBReachability.h"
#import "CalendarBookingPresenter.h"
#import "CalendarDataLoaderFactory.h"
#import "CalendarDataProcessors.h"

@interface CalendarWeekViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) CalendarDataSource *calendarDataSource;
@property (nonatomic, strong) CalendarGridCollectionViewLayout *calendarGridLayout;
@property (nonatomic, weak, nullable) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak, nullable) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak, nullable) IBOutlet UILabel *datesIntervalLabel;
@property (nonatomic, weak, nullable) IBOutlet UIButton *prevWeekButton;
@property (nonatomic, weak, nullable) IBOutlet UIView *topToolBar;
@property (nonatomic, weak) IBOutlet UILabel *noCollectionLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong, nonnull) NSDateIntervalFormatter *dateIntervalFormatter;
@property (nonatomic, strong) NSObject <CalendarDataLoader> *dataLoader;

@end

@implementation CalendarWeekViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.filter = [SBGetBookingsFilter todayBookingsFilter];
    self.filter.order = kSBGetBookingsFilterOrderByStartDate;
    SBUser *user = [SBSession defaultSession].user;
    NSAssert(user != nil, @"no user found");
    if (![user hasAccessToACLRule:SBACLRulePerformersFullListAccess]) {
        NSAssert(user.associatedPerformerID != nil && ![user.associatedPerformerID isEqualToString:@""], @"invalid associated performer value");
        self.filter.unitGroupID = user.associatedPerformerID;
    }
    [self configureFilter:self.filter withWeekRangeForDate:[NSDate date]];
    
    self.topToolBar.backgroundColor = [UIColor sb_navigationBarColor];

    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recognizeTapGesture:)];
    tapGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    self.collectionView.allowsMultipleSelection = YES;

    self.calendarDataSource = [CalendarDataSource new];
    self.calendarDataSource.displayServiceForWideLayout = YES;
    self.calendarDataSource.displayPerformerForWideLayout = YES;
    self.collectionView.dataSource = self.calendarDataSource;
    [self.calendarDataSource configureCollectionView:self.collectionView];

    self.calendarGridLayout = [CalendarGridCollectionViewLayout new];
    self.calendarGridLayout.dataSource = self.calendarDataSource;
    self.collectionView.collectionViewLayout = self.calendarGridLayout;

    self.prevWeekButton.transform = CGAffineTransformRotate(self.prevWeekButton.transform, M_PI);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotificationHandler:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didInvalidateCacheNotificationHandler:)
                                                 name:kSBCache_DidInvalidateCacheForRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didInvalidateCacheNotificationHandler:)
                                                 name:kSBCache_DidInvalidateCacheNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSBCache_DidInvalidateCacheForRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSBCache_DidInvalidateCacheNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    SBReachability *reach = [SBReachability reachabilityWithHostname:kSBReachabilityHostname];
    reach.reachabilityBlock = ^(SBReachability *reachability, SCNetworkConnectionFlags flags) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (flags & kSCNetworkFlagsReachable) {
                self.noCollectionLabel.hidden = YES;
                SBRequest *checkPluginRequest = [[SBSession defaultSession] isPluginActivated:kSBPluginRepositoryApproveBookingPlugin callback:^(SBResponse<NSNumber *> * _Nonnull response) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryApproveBookingPlugin enabled:[response.result boolValue]];
                        [self.activityIndicator stopAnimating];
                        [self configureFilter:self.filter withWeekRangeForDate:[NSDate date]];
                        [self loadData];
                    });
                }];
                [self.activityIndicator startAnimating];
                [[SBSession defaultSession] performReqeust:checkPluginRequest];
            } else {
                self.noCollectionLabel.hidden = NO;
            }
        });
    };
    [reach startNotifier];
}

- (NSObject<CalendarDataLoader> *)dataLoader
{
    if (!_dataLoader) {
        _dataLoader = [CalendarDataLoaderFactory dataLoaderForType:self.dataLoaderType];
        [_dataLoader addDataProcessor:[[CalendarDataPerformersLocalSaverDataProcessor alloc] init]];
        [_dataLoader addDataProcessor:[[CalendarDataBookingsDataLocalSaverProcessor alloc] init]];
        NSAssert(_dataLoader != nil, @"No data loader.");
        if (!_dataLoader) {
            return nil;
        }
    }
    return _dataLoader;
}

- (void)loadData
{
    NSAssert(self.filter != nil, @"no filter");
    NSAssert(self.filter.from != nil, @"no date selected");

    self.datesIntervalLabel.text = [self.dateIntervalFormatter stringFromDate:self.filter.from toDate:self.filter.to];
    
    [self.activityIndicator startAnimating];
    [self.dataLoader loadDataWithFilter:self.filter callback:^(CalendarDataLoaderResult * _Nonnull result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            if (result.error) {
                if (result.error.code != SBUserCancelledErrorCode) {
                    if (!result.error.isNetworkConnectionError) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLS(@"Error",@"")
                                                                                       message:[result.error message]
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"OK",@"") style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                    else if (result.error.isNetworkConnectionError) {
                        self.noCollectionLabel.hidden = NO;
                    }
                }
            } else {
                self.calendarDataSource.displayPerformerForWideLayout = self.dataLoader.recommendsDisplayPerformer;
                self.calendarDataSource.displayServiceForWideLayout = self.dataLoader.recommendsDisplayService;
                [self.calendarDataSource setTimeframeStep:result.timeframeStep];
                [self.calendarGridLayout setWorkingHoursMatrix:result.workingHoursMatrix];
                [self.calendarDataSource setWorkingHoursMatrix:result.workingHoursMatrix];
                [self.calendarDataSource setSections:result.sections];
                [self.calendarDataSource setBookings:result.bookings sortingStrategy:CalendarGridBookingsLayoutSortingStrategy];
                
                [self.calendarDataSource resetPresenters];
                [self.calendarDataSource addPresenter:[CalendarBookingDefaultPresenter presenter]];
                if (result.performers) {
                    [self.calendarDataSource addPresenter:[[CalendarBookingPerformerPresenter alloc] initWithPerformers:result.performers]];
                }
                if (result.statuses) {
                    [self.calendarDataSource addPresenter:[[CalendarBookingStatusPresenter alloc] initWithStatuses:result.statuses]];
                }
                
                [self.collectionView reloadData];
                [self.collectionView.collectionViewLayout invalidateLayout];
                [self.collectionView setContentOffset:CGPointZero animated:YES];
            }
        });
    }];
}

- (NSDateIntervalFormatter *)dateIntervalFormatter
{
    if (!_dateIntervalFormatter) {
        _dateIntervalFormatter = [NSDateIntervalFormatter new];
        [_dateIntervalFormatter setDateStyle:NSDateIntervalFormatterMediumStyle];
        [_dateIntervalFormatter setTimeStyle:NSDateIntervalFormatterNoStyle];
    }
    return _dateIntervalFormatter;
}

- (void)configureFilter:(SBGetBookingsFilter *)filter withWeekRangeForDate:(NSDate *)date
{
    NSCalendar *calendar = [NSDate sb_calendar];
    NSInteger currentWeekday = [calendar component:NSCalendarUnitWeekday fromDate:date];
    NSDateComponents *components = [NSDateComponents new];
    NSInteger firstWeekday = [calendar firstWeekday];
    SBSession *session = [SBSession defaultSession];
    if ([session.settings objectForKey:kSBSettingsCalendarFirstWeekdayKey]) {
        firstWeekday = [[session.settings objectForKey:kSBSettingsCalendarFirstWeekdayKey] integerValue];
    }
    if (firstWeekday == 2) { // first day of the week is Monday
        components.day = (currentWeekday == 1 ? -6 : 1 - (currentWeekday - 1));
    }
    else { // first day of the week is Sunday
        components.day = (currentWeekday == 1 ? 0 : 1 - currentWeekday);
    }
    NSDate *weekStart = [calendar dateByAddingComponents:components toDate:date options:0];
    components.day = +6;
    NSDate *weekEnd = [calendar dateByAddingComponents:components toDate:weekStart options:0];
    filter.from = weekStart;
    filter.to = weekEnd;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if (![self.dataLoader isLoading] || self.calendarDataSource.timeframeStep) {
        self.calendarDataSource.traitCollection = self.traitCollection;
        [self.calendarDataSource clearNewBookingPlaceholderAtIndexPath];
        [self.collectionView reloadData];
    }
    self.tabBarController.tabBar.hidden = [self.traitCollection isWideLayout] && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
    self.collectionView.showsHorizontalScrollIndicator = [self.traitCollection isWideLayout];
}

#pragma mark - Actions

- (IBAction)prevWeekAction:(id)sender
{
    NSCalendar *calendar = [NSDate sb_calendar];
    NSDateComponents *components = [NSDateComponents new];
    components.day = -7;
    self.filter.from = [calendar dateByAddingComponents:components toDate:self.filter.from options:0];
    self.filter.to = [calendar dateByAddingComponents:components toDate:self.filter.to options:0];
    [self loadData];
}

- (IBAction)nextWeekAction:(id)sender
{
    NSCalendar *calendar = [NSDate sb_calendar];
    NSDateComponents *components = [NSDateComponents new];
    components.day = 7;
    self.filter.from = [calendar dateByAddingComponents:components toDate:self.filter.from options:0];
    self.filter.to = [calendar dateByAddingComponents:components toDate:self.filter.to options:0];
    [self loadData];
}

- (void)refreshAction:(id)sender
{
    [self.activityIndicator startAnimating];
    [self.dataLoader refreshDataWithFilter:self.filter callback:^(CalendarDataLoaderResult * _Nonnull result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            if (result.error) {
                if (result.error.code != SBUserCancelledErrorCode) {
                    if (!result.error.isNetworkConnectionError) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLS(@"Error",@"")
                                                                                       message:[result.error message]
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"OK",@"") style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                    else if (result.error.isNetworkConnectionError) {
                        self.noCollectionLabel.hidden = NO;
                    }
                }
            } else {
                [self.refreshControl endRefreshing];
                [self.calendarDataSource setBookings:result.bookings sortingStrategy:CalendarGridBookingsLayoutSortingStrategy];
                [self.collectionView reloadData];
                [self.collectionView.collectionViewLayout invalidateLayout];
                [self.collectionView setContentOffset:CGPointZero animated:YES];
            }
        });
    }];
}

- (IBAction)showTodayAction:(id)sender
{
    [self configureFilter:self.filter withWeekRangeForDate:[NSDate date]];
    [self loadData];
}

- (void)recognizeTapGesture:(UITapGestureRecognizer *)recognizer
{
    CGPoint position = [recognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.calendarGridLayout indexPathForCellAtPosition:position];
    if (indexPath && self.calendarDataSource.workingHoursMatrix.hours.count > indexPath.item) {
        NSUInteger timeStepOffset = [self.calendarGridLayout timeStepOffsetForCellAtPosition:position
                                                                         calculatedIndexPath:indexPath];
        NSDate *startDate = [self.calendarDataSource.workingHoursMatrix.hours[indexPath.item] dateByAddingTimeInterval:timeStepOffset * self.calendarDataSource.timeframeStep * 60];
        startDate = [(NSDate *)[self.calendarDataSource.sections[indexPath.section] sectionID] dateByAssigningTimeComponentsFromDate:startDate];
        NSDate *endHour = [startDate dateByAddingTimeInterval:self.calendarDataSource.timeframeStep * 60];
        SBNewBookingPlaceholder *placeholder = [SBNewBookingPlaceholder new];
        placeholder.startDate = startDate;
        placeholder.endDate = endHour;
        [self.calendarDataSource addNewBookingPlaceholder:placeholder forSection:indexPath.section];
    }
}

#pragma mark - Notification handlers

- (void)didInvalidateCacheNotificationHandler:(NSNotification *)notification
{
    if ((notification.userInfo[kSBCache_RequestObjectUserInfoKey] && [notification.userInfo[kSBCache_RequestObjectUserInfoKey] isKindOfClass:[SBGetBookingsRequest class]])
        || (notification.userInfo[kSBCache_RequestClassUserInfoKey] && [notification.userInfo[kSBCache_RequestClassUserInfoKey] isSubclassOfClass:[SBGetBookingsRequest class]])) {
        [self refreshAction:nil];
    } else if ([notification.name isEqualToString:kSBCache_DidInvalidateCacheNotification]) {
        [self loadData];
    }
}

- (void)applicationWillEnterForegroundNotificationHandler:(NSNotification *)notification
{
    [self loadData];
}

#pragma mark - CalendarViewContainerChildController

- (SBGetBookingsFilter *)getBookingsFilter
{
    return self.filter;
}

- (void)showAddBookingForm
{
    [self performSegueWithIdentifier:@"addBooking" sender:self];
}

- (void)filterDidChange:(nonnull SBGetBookingsFilter *)filter requiresReset:(BOOL)reset
{
    NSParameterAssert(filter != nil);
    if (![filter isEqual:self.filter]) {
        self.filter = filter;
        [self loadData];
    }
}

- (void)willEmbedToCalendarViewContainer:(nonnull UIViewController *)viewContainer
{
    NSParameterAssert(viewContainer != nil);
    self.topToolBar.backgroundColor = viewContainer.navigationController.navigationBar.backgroundColor;
}

- (void)willRemoveFromCalendarViewContainer:(nonnull UIViewController *)viewContainer
{
    NSParameterAssert(viewContainer != nil);
    [self.calendarGridLayout finilize];
}

- (void)didEmbedToCalendarViewContainer:(nonnull UIViewController *)viewContainer
{
    NSParameterAssert(viewContainer != nil);
    UIBarButtonItem *todayButton = [[UIBarButtonItem alloc] initWithTitle:NSLS(@"Current Week",@"")
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self action:@selector(showTodayAction:)];
    [viewContainer.navigationItem setLeftBarButtonItem:todayButton animated:YES];

}

- (void)didRemoveFromCalendarViewContainer:(nonnull UIViewController *)viewContainer
{
    NSParameterAssert(viewContainer != nil);
    [viewContainer.navigationItem setLeftBarButtonItem:nil animated:YES];
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    SBUser *user = [SBSession defaultSession].user;
    NSAssert(user != nil, @"no user found");
    if (![user hasAccessToACLRule:SBACLRuleEditBooking] && ![user hasAccessToACLRule:SBACLRuleEditOwnBooking]) {
        return NO;
    }
    return [self.collectionView indexPathForItemAtPoint:[touch locationInView:self.collectionView]] == nil;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *candidates = [self.calendarGridLayout indexPathsForItemsCompetitorsToItemAtIndexPath:indexPath];
    [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    [candidates enumerateObjectsUsingBlock:^(NSIndexPath *obj, NSUInteger idx, BOOL *stop) {
        [self.collectionView selectItemAtIndexPath:obj animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }];

    NSObject<SBBookingProtocol> *booking = [self.calendarDataSource bookingAtIndexPath:indexPath];
    if ([booking isKindOfClass:[SBBooking class]]) {
        if (candidates.count == 1) {
            if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                [self performSegueWithIdentifier:@"showBookingDetails-iPad" sender:self];
            }
            else {
                [self performSegueWithIdentifier:@"showBookingDetails" sender:self];
            }
        }
        else {
            if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                [self performSegueWithIdentifier:@"showBookingList-iPad" sender:self];
            }
            else {
                [self performSegueWithIdentifier:@"showBookingList" sender:self];
            }
        }
    }
    else if ([booking isKindOfClass:[SBNewBookingPlaceholder class]]) {
        [self performSegueWithIdentifier:@"addBooking" sender:self];
    }
}

#pragma mark - Navigation Stack

- (BOOL)shouldPerformSegueWithIdentifier:(nonnull NSString *)identifier sender:(id)sender
{
    NSParameterAssert(identifier != nil);
    if ([identifier isEqualToString:@"showBookingDetails"]
            || [identifier isEqualToString:@"showBookingDetails-iPad"])
    {
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        if (!indexPath) {
            return NO;
        }
        SBBooking *booking = (SBBooking *)[self.calendarDataSource bookingAtIndexPath:indexPath];
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
            || [segue.identifier isEqualToString:@"showBookingDetails-iPad"]) {
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        NSAssert(indexPath != nil, @"no selected bookings");
        SBBooking *booking = (SBBooking *) [self.calendarDataSource bookingAtIndexPath:indexPath];
        BookingDetailsViewController *controller = nil;
        if ([segue.identifier isEqualToString:@"showBookingDetails"]) {
            controller = segue.destinationViewController;
        }
        else if ([segue.identifier isEqualToString:@"showBookingDetails-iPad"]) {
            NSAssert([segue.destinationViewController isKindOfClass:[UINavigationController class]], @"unexpected view controllers hierarchy");
            controller = (BookingDetailsViewController *) [(UINavigationController *) segue.destinationViewController topViewController];
        }
        controller.bookingID = booking.bookingID;
        controller.clientName = booking.clientName;
        controller.clientEmail = booking.clientEmail;
        controller.clientPhone = booking.clientPhone;
        controller.onBookingCanceledHandler = ^(NSString *bookingID) {
            [self loadData];
        };
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    else if ([segue.identifier isEqualToString:@"showBookingList"]
            || [segue.identifier isEqualToString:@"showBookingList-iPad"]) {
        NSArray <NSIndexPath *> *indexPaths = [self.collectionView indexPathsForSelectedItems];
        NSAssert(indexPaths.count > 0, @"no selected bookings");
        NSMutableArray <SBBookingObject *> *bookings = [NSMutableArray array];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            [bookings addObject:[self.calendarDataSource bookingAtIndexPath:indexPath]];
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }];
        BookingsListViewController *controller = nil;
        if ([segue.identifier isEqualToString:@"showBookingList"]) {
            controller = (BookingsListViewController *)segue.destinationViewController;
        }
        else if ([segue.identifier isEqualToString:@"showBookingList-iPad"]) {
            controller = (BookingsListViewController *)[(UINavigationController *) segue.destinationViewController topViewController];
        }
        controller.timeframeStep = self.calendarDataSource.timeframeStep;
        controller.bookings = bookings;
    }
    else if ([segue.identifier isEqualToString:@"addBooking"]) {
        AddBookingViewController *controller = (AddBookingViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
        controller.timeFrameStep = self.calendarDataSource.timeframeStep;
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        if (indexPath) {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
            NSObject<SBBookingProtocol> *booking = [self.calendarDataSource bookingAtIndexPath:indexPath];
            controller.initialDate = (booking.startDate ? booking.startDate : [NSDate date]);
            controller.preferedStartTime = booking.startDate;
        }
        else {
            controller.initialDate = [NSDate date];
        }
        controller.bookingCreatedHandler = ^(UIViewController *_controller) {
            AddBookingViewController *addBookingController = (AddBookingViewController *)_controller;
            [self dismissViewControllerAnimated:YES completion:nil];
            [self configureFilter:self.filter withWeekRangeForDate:addBookingController.bookingForm.startDate];
            [self loadData];
        };
        controller.bookingCanceledHandler = ^(UIViewController *_controller) {
            [self.calendarDataSource clearNewBookingPlaceholderAtIndexPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        };
    }
}

@end
