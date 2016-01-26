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
#import "SBPerformer.h"

@interface CalendarDayViewController () <UIGestureRecognizerDelegate>
{
    NSMutableArray *pendingRequests;
}

@property (nonatomic, weak) IBOutlet LSWeekView *weekView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *noWorkingHoursLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) CalendarDataSource *calendarDataSource;
@property (nonatomic, strong) CalendarGridCollectionViewLayout *calendarGridLayout;
@property (nonatomic, strong) CalendarListCollectionViewLayout *calendarListLayout;
@property (nonatomic, getter=isLoading) BOOL loading;

@end

@implementation CalendarDayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.filter = [SBGetBookingsFilter todayBookingsFilter];
    self.filter.order = kSBGetBookingsFilterOrderByStartDate;

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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSBSessionManagerDidEndSessionNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveRemoteNotification object:nil];
    [self.calendarGridLayout finilize];
    [self.calendarListLayout finilize];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
                self.filter = [SBGetBookingsFilter todayBookingsFilter];
                self.filter.order = kSBGetBookingsFilterOrderByStartDate;
                [self loadData];
            });
        }];
        self.activityIndicator.hidden = NO;
        [[SBSession defaultSession] performReqeust:checkPluginRequest];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if (![self isLoading] || self.calendarDataSource.timeframeStep) {
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

- (void)loadData
{
    NSAssert(self.filter != nil, @"no filter");
    NSAssert(self.filter.from != nil, @"no date selected");

    SBSession *session = [SBSession defaultSession];
    [session cancelRequests:pendingRequests];
    NSAssert(session != nil, @"no active session");

    SBRequestsGroup *group = [SBRequestsGroup new];

    __block NSInteger timeframeStep = 0;
    SBRequest *loadCompanyInfoRequest = [session getCompanyInfoWithCallback:^(SBResponse *response) {
        SBCompanyInfo *companyInfo = response.result;
        timeframeStep = [companyInfo.timeframe integerValue];
    }];
    [group addRequest:loadCompanyInfoRequest];

    __block NSDictionary *workingHours = nil;
    SBRequest *loadTimeframeRequest = [session getWorkDaysTimesForDate:self.filter.from callback:^(SBResponse *response) {
        workingHours = response.result;
    }];
    [group addRequest:loadTimeframeRequest];

    NSMutableArray *sections = [NSMutableArray array];
    SBRequest *loadPerformersRequest = [session getUnitList:^(SBResponse<SBPerformersCollection *> *response) {
        [sections removeAllObjects];
        NSPredicate *sectionPredicate = [NSPredicate predicateWithBlock:^BOOL(NSObject<SBBookingProtocol> * evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject.performerID isEqualToString:bindings[kCalendarSectionDataSourcePerformerIDBindingKey]];
        }];
        [response.result enumerateUsingBlock:^(NSString * _Nonnull performerID, SBPerformer * _Nonnull performer, BOOL * _Nonnull stop) {
            NSDictionary *bindings = @{kCalendarSectionDataSourcePerformerIDBindingKey: performerID};
            CalendarSectionDataSource *section = [[CalendarSectionDataSource alloc] initWithTitle:performer.name
                                                                                        predicate:sectionPredicate
                                                                            substitutionVariables:bindings];
            section.sectionID = performerID;
            [sections addObject:section];
        }];
    }];
    [group addRequest:loadPerformersRequest];

    __block SBBookingStatusesCollection *statuses = nil;
    SBRequest *loadStatusesRequest = [session getStatusesList:^(SBResponse <SBBookingStatusesCollection *> *response) {
        statuses = response.result;
    }];
    [group addRequest:loadStatusesRequest];

    __block NSArray <SBBooking *> *bookings = nil;
    SBRequest *loadBookingsRequest = [[SBSession defaultSession] getBookingsWithFilter:self.filter callback:^(SBResponse *response) {
        bookings = response.result;
    }];
    loadBookingsRequest.cachePolicy = SBIgnoreCachePolicy;
    [loadBookingsRequest addDependency:loadTimeframeRequest];
    [loadBookingsRequest addDependency:loadStatusesRequest];
    [group addRequest:loadBookingsRequest];

    group.callback = ^(SBResponse *response) {
        [pendingRequests removeObject:response.requestGUID];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.activityIndicator.hidden = YES;
            if (response.error) {
                if (!response.canceled) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                    message:[response.error message]
                                                                   delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            } else {
                self.loading = NO;
                [self.calendarDataSource setTimeframeStep:timeframeStep];
                SBWorkingHoursMatrix *workingHoursMatrix = [[SBWorkingHoursMatrix alloc] initWithData:workingHours forDate:self.filter.from];
                [workingHoursMatrix updateDatesUsingBookingsInfo:bookings];
                [self.calendarGridLayout setWorkingHoursMatrix:workingHoursMatrix];
                [self.calendarListLayout setWorkingHoursMatrix:workingHoursMatrix];
                [self.calendarDataSource setWorkingHoursMatrix:workingHoursMatrix];
                [self.calendarDataSource setSections:sections];
                [self.calendarDataSource setStatusesCollection:statuses];
                [self.calendarDataSource setBookings:bookings sortingStrategy:CalendarGridBookingsLayoutSortingStrategy];
                [self.collectionView reloadData];
                [self.collectionView.collectionViewLayout invalidateLayout];
                [self.collectionView setContentOffset:CGPointZero animated:YES];
                self.noWorkingHoursLabel.hidden = (workingHoursMatrix.hours.count != 0);
            }
        });
    };
    self.activityIndicator.hidden = NO;
    [pendingRequests addObject:group.GUID];
    self.loading = YES;
    [session performReqeust:group];
}

#pragma mark - Actions

- (void)refreshAction:(id)sender
{
    [[SBSession defaultSession] cancelRequests:pendingRequests];
    SBRequest *request = [[SBSession defaultSession] getBookingsWithFilter:self.filter callback:^(SBResponse *response) {
        [pendingRequests removeObject:response.requestGUID];
        if (response.error && !response.canceled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                message:[response.error message]
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"")
                                                      otherButtonTitles:nil];
                [alert show];
            });
            return ;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
            [self.calendarDataSource setBookings:response.result sortingStrategy:CalendarGridBookingsLayoutSortingStrategy];
            [self.collectionView reloadData];
            [self.collectionView.collectionViewLayout invalidateLayout];
            [self.collectionView setContentOffset:CGPointZero animated:YES];
        });
    }];
    request.cachePolicy = SBIgnoreCachePolicy;
    [pendingRequests addObject:request.GUID];
    [[SBSession defaultSession] performReqeust:request];
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
    if (indexPath) {
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

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
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
        controller.statuses = self.calendarDataSource.statuses;
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
            controller.preferedPerformerID = (NSString *) section.sectionID;
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
