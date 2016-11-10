//
//  CalendarDayViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarDayViewController.h"
#import "CalendarDataSource.h"
#import "CalendarGridCollectionViewLayout.h"
#import "SBGetBookingsFilter.h"
#import "SBGetBookingsRequest.h"
#import "CalendarListCollectionViewLayout.h"
#import "UIColor+SimplyBookColors.h"
#import "NSDate+TimeManipulation.h"
#import "LSWeekView.h"
#import "NSDateFormatter+ServerParser.h"
#import "AddBookingViewController.h"
#import "BookingsListViewController.h"
#import "BookingDetailsViewController.h"
#import "SBSession.h"
#import "SBWorkingHoursMatrix.h"
#import "NSError+SimplyBook.h"
#import "CalendarSectionDataSource.h"
#import "SBRequestsGroup.h"
#import "UITraitCollection+SimplyBookLayout.h"
#import "SBCompanyInfo.h"
#import "AppDelegate.h"
#import "SBNewBookingPlaceholder.h"
#import "SBSessionManager.h"
#import "SBBookingStatusesCollection.h"
#import "SBPluginsRepository.h"
#import "SBReachability.h"
#import "SBUser.h"
#import "CalendarBookingPresenter.h"
#import "CalendarDataLoaderFactory.h"
#import "CalendarDataProcessors.h"

@interface CalendarDayViewController () <UIGestureRecognizerDelegate>
{
    NSMutableArray *pendingRequests;
}

@property (nonatomic, weak) IBOutlet LSWeekView *weekView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *noWorkingHoursLabel;
@property (nonatomic, weak) IBOutlet UILabel *noCollectionLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSObject <CalendarDataLoader> *dataLoader;
@property (nonatomic, strong) CalendarDataSource *calendarDataSource;
@property (nonatomic, strong) CalendarGridCollectionViewLayout *calendarGridLayout;
@property (nonatomic, strong) CalendarListCollectionViewLayout *calendarListLayout;
@property (nonatomic, getter=isLoading) BOOL loading;

@end

@implementation CalendarDayViewController

@synthesize dataLoader = _dataLoader;

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

    SBSession *session = [SBSession defaultSession];
    if ([session.settings objectForKey:kSBSettingsCalendarFirstWeekdayKey]) {
        self.weekView.firstWeekday = [[session.settings objectForKey:kSBSettingsCalendarFirstWeekdayKey] integerValue];
    }
    [self.weekView reloadData];
    self.weekView.backgroundColor = [UIColor sb_navigationBarColor];
    __weak typeof (self) weakSelf = self;
    self.weekView.didChangeSelectedDateBlock = ^(NSDate *date) {
        self.calendarGridLayout.showCurrentTimeLine = [date isToday];
        self.calendarListLayout.showCurrentTimeLine = [date isToday];
        weakSelf.filter.from = date;
        weakSelf.filter.to = date;
        [weakSelf loadData];
    };
    pendingRequests = [NSMutableArray array];

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

    self.calendarListLayout = [CalendarListCollectionViewLayout new];
    self.calendarListLayout.dataSource = self.calendarDataSource;
    
    self.calendarGridLayout.showCurrentTimeLine = YES;
    self.calendarListLayout.showCurrentTimeLine = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveRemoteNotificationHandler:)
                                                 name:UIApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidEndNotificationHandler:)
                                                 name:kSBSessionManagerDidEndSessionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotificationHandler:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSBSessionManagerDidEndSessionNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [self.calendarGridLayout finilize];
    [self.calendarListLayout finilize];
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
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                if (appDelegate.pushNotification) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                    NSString *push = appDelegate.pushNotification[@"aps"][@"alert"];
                    push = [[push componentsSeparatedByString:@" at "] lastObject];
                    NSDate *date = [[NSDateFormatter sb_pushNotificationTimeParser] dateFromString:push];
                    self.filter.from = date;
                    self.filter.to = date;
                    [self.weekView setSelectedDate:date animated:YES];
                    [self.refreshControl beginRefreshing];
                    [self refreshAction:nil];
                    appDelegate.pushNotification = nil;
                }
                else {
                    SBRequest *checkPluginRequest = [[SBSession defaultSession] isPluginActivated:kSBPluginRepositoryApproveBookingPlugin callback:^(SBResponse<NSNumber *> * _Nonnull response) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryApproveBookingPlugin enabled:[response.result boolValue]];
                            self.activityIndicator.hidden = YES;
                            [self loadData];
                        });
                    }];
                    self.activityIndicator.hidden = NO;
                    [[SBSession defaultSession] performReqeust:checkPluginRequest];
                }
            } else {
                self.noCollectionLabel.hidden = NO;
            }
        });
    };
    [reach startNotifier];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if (!([self isLoading] && self.dataLoader.isLoading) || self.calendarDataSource.timeframeStep) {
        if ([self.traitCollection isWideLayout]) {
            self.collectionView.collectionViewLayout = self.calendarGridLayout;
        }
        else {
            self.collectionView.collectionViewLayout = self.calendarListLayout;
        }
        self.calendarDataSource.traitCollection = self.traitCollection;
        [self.calendarDataSource clearNewBookingPlaceholderAtIndexPath];
        [self.collectionView reloadData];
    }
    self.tabBarController.tabBar.hidden = [self.traitCollection isWideLayout] && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
    self.collectionView.showsHorizontalScrollIndicator = [self.traitCollection isWideLayout];
    [self.weekView traitCollectionDidChange:previousTraitCollection];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.weekView reloadData];
    }];
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

    self.activityIndicator.hidden = NO;
    [self.dataLoader loadDataWithFilter:self.filter callback:^(CalendarDataLoaderResult * _Nonnull result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.activityIndicator.hidden = YES;
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
                [self.calendarListLayout setWorkingHoursMatrix:result.workingHoursMatrix];
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
                self.noWorkingHoursLabel.hidden = (result.workingHoursMatrix.hours.count != 0);
                [self loadGoogleCalendarBusiTime];
            }
        });
    }];
}

- (SBRequest *)requestForGoogleCalendarBusyTime
{
    if ([[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryGoogleCalendarSyncPlugin] == nil) {
        SBRequest *pluginCheckRequest = [[SBSession defaultSession] isPluginActivated:kSBPluginRepositoryGoogleCalendarSyncPlugin callback:^(SBResponse<id> * _Nonnull response) {
            [pendingRequests removeObject:response.requestGUID];
            if (response.result) {
                [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryGoogleCalendarSyncPlugin enabled:[response.result boolValue]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadGoogleCalendarBusiTime];
            });
        }];
        return pluginCheckRequest;
    }
    if (!self.calendarDataSource || !self.calendarDataSource.sections || ![[SBPluginsRepository repository] isPluginEnabled:kSBPluginRepositoryGoogleCalendarSyncPlugin].boolValue) {
        return nil;
    }
    SBRequestsGroup *group = [SBRequestsGroup new];
    NSDate *from = [self.filter.from dateWithZeroTime];
    NSDate *to = [from nextDayDate];
    for (CalendarSectionDataSource *section in self.calendarDataSource.sections) {
        SBRequest *r = [[SBSession defaultSession] getGoogleCalendarBusyTimeFromDate:from toDate:to
                                                                              unitID:(NSString *)section.sectionID
                                                                            callback:^(SBResponse<id> * _Nonnull response)
        {
            if (!response.error) {
                [self.calendarDataSource setGoogleCalendarBusyTime:response.result forSectionID:(NSString *)section.sectionID];
            }
        }];
        [group addRequest:r];
    }
    group.callback = ^(SBResponse *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [pendingRequests removeObject:response.requestGUID];
            self.loading = NO;
            self.activityIndicator.hidden = YES;
            [self.collectionView.collectionViewLayout invalidateLayout];
        });
    };
    return group;
}

- (void)loadGoogleCalendarBusiTime
{
    SBRequest *request = [self requestForGoogleCalendarBusyTime];
    if (request) {
        self.loading = YES;
        self.activityIndicator.hidden = NO;
        [pendingRequests addObject:request.GUID];
        [[SBSession defaultSession] performReqeust:request];
    }
}

#pragma mark - Actions

- (void)refreshAction:(id)sender
{
    [self.dataLoader refreshDataWithFilter:self.filter callback:^(CalendarDataLoaderResult * _Nonnull result) {
        dispatch_async(dispatch_get_main_queue(), ^{
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
                [self loadGoogleCalendarBusiTime];
            }
        });
    }];
}

- (IBAction)showTodayAction:(id)sender
{
    [self.weekView setSelectedDate:[NSDate date] animated:YES];
    self.filter.from = [NSDate date];
    self.filter.to = [NSDate date];
    [self loadData];
}

- (void)recognizeTapGesture:(UITapGestureRecognizer *)recognizer
{
    CGPoint position = [recognizer locationInView:self.collectionView];
    CalendarGridCollectionViewLayout *layout = nil;
    if (self.collectionView.collectionViewLayout == self.calendarGridLayout) {
        layout = self.calendarGridLayout;
    }
    else {
        layout = self.calendarListLayout;
    }
    NSIndexPath *indexPath = [layout indexPathForCellAtPosition:position];
    if (indexPath && self.calendarDataSource.workingHoursMatrix.hours.count > indexPath.item) {
        NSUInteger timeStep = [layout timeStepOffsetForCellAtPosition:position calculatedIndexPath:indexPath];
        NSDate *startHour = [self.calendarDataSource.workingHoursMatrix.hours[indexPath.item] dateByAddingTimeInterval:timeStep * self.calendarDataSource.timeframeStep * 60];
        NSDate *endHour = [startHour dateByAddingTimeInterval:self.calendarDataSource.timeframeStep * 60];
        SBNewBookingPlaceholder *placeholder = [SBNewBookingPlaceholder new];
        placeholder.startDate = startHour;
        placeholder.endDate = endHour;
        [self.calendarDataSource addNewBookingPlaceholder:placeholder forSection:indexPath.section];
    }
}

#pragma mark - Notification handlers

- (void)applicationDidReceiveRemoteNotificationHandler:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
        NSString *push = notification.userInfo[@"aps"][@"alert"];
        push = [[push componentsSeparatedByString:@" at "] lastObject];
        NSDate *date = [[NSDateFormatter sb_pushNotificationTimeParser] dateFromString:push];
        if (date) {
            self.filter.from = date;
            self.filter.to = date;
            [self.weekView setSelectedDate:date animated:YES];
            [self loadData];
        }
    });
}

- (void)sessionDidEndNotificationHandler:(NSNotification *)notification
{
    [self.calendarGridLayout finilize];
    [self.calendarListLayout finilize];
}

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

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    SBUser *user = [SBSession defaultSession].user;
    NSAssert(user != nil, @"no user found");
    if (![user hasAccessToACLRule:SBACLRuleEditBooking] && ![user hasAccessToACLRule:SBACLRuleEditOwnBooking]) {
        return NO;
    }
    [self.collectionView.collectionViewLayout invalidateLayout];
    return [self.collectionView indexPathForItemAtPoint:[touch locationInView:self.collectionView]] == nil;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *candidates = nil;
    if (self.collectionView.collectionViewLayout == self.calendarGridLayout) {
        candidates = [self.calendarGridLayout indexPathsForItemsCompetitorsToItemAtIndexPath:indexPath];
    }
    else {
        candidates = [self.calendarListLayout indexPathsForItemsCompetitorsToItemAtIndexPath:indexPath];
    }
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
}

- (void)willRemoveFromCalendarViewContainer:(nonnull UIViewController *)viewContainer
{
    NSParameterAssert(viewContainer != nil);
    [viewContainer.navigationItem setLeftBarButtonItem:nil animated:YES];
    [self.calendarGridLayout finilize];
    [self.calendarListLayout finilize];
}

- (void)didEmbedToCalendarViewContainer:(nonnull UIViewController *)viewContainer
{
    NSParameterAssert(viewContainer != nil);
    UIBarButtonItem *todayButton = [[UIBarButtonItem alloc] initWithTitle:NSLS(@"Today",@"")
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self action:@selector(showTodayAction:)];
    [viewContainer.navigationItem setLeftBarButtonItem:todayButton animated:YES];
}

- (void)didRemoveFromCalendarViewContainer:(nonnull UIViewController *)viewContainer
{
    NSParameterAssert(viewContainer != nil);
    [viewContainer.navigationItem setLeftBarButtonItem:nil animated:YES];
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
            CalendarSectionDataSource *section = self.calendarDataSource.sections[indexPath.section];
            controller.preferedPerformerID = section.performerID;
            controller.preferedServiceID = section.serviceID;
        }
        else {
            controller.initialDate = self.weekView.selectedDate;
        }
        controller.bookingCreatedHandler = ^(UIViewController *controller) {
            AddBookingViewController *addBookingController = (AddBookingViewController *)controller;
            [self dismissViewControllerAnimated:YES completion:nil];
            [self.weekView setSelectedDate:addBookingController.bookingForm.startDate animated:YES];
            self.filter.from = addBookingController.bookingForm.startDate;
            self.filter.to = addBookingController.bookingForm.startDate;
            [self loadData];
        };
        controller.bookingCanceledHandler = ^(UIViewController *controller) {
            [self.calendarDataSource clearNewBookingPlaceholderAtIndexPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        };
    }
}

@end
