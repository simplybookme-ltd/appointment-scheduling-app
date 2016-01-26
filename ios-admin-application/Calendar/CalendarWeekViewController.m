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
#import "SBRequestsGroup.h"
#import "SBCompanyInfo.h"
#import "SBWorkingHoursMatrix.h"
#import "NSDateFormatter+ServerParser.h"
#import "UIColor+SimplyBookColors.h"
#import "SBNewBookingPlaceholder.h"
#import "UITraitCollection+SimplyBookLayout.h"
#import "SBPluginsRepository.h"

@interface CalendarWeekViewController () <UIGestureRecognizerDelegate>
{
    NSMutableArray *pendingRequests;
}

@property (nonatomic, strong) CalendarDataSource *calendarDataSource;
@property (nonatomic, strong) CalendarGridCollectionViewLayout *calendarGridLayout;
@property (nonatomic, weak, nullable) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak, nullable) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak, nullable) IBOutlet UILabel *datesIntervalLabel;
@property (nonatomic, weak, nullable) IBOutlet UIButton *prevWeekButton;
@property (nonatomic, weak, nullable) IBOutlet UIView *topToolBar;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong, nonnull) NSDateIntervalFormatter *dateIntervalFormatter;
@property (nonatomic, getter=isLoading) BOOL loading;

@end

@implementation CalendarWeekViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.filter = [SBGetBookingsFilter todayBookingsFilter];
    self.filter.order = kSBGetBookingsFilterOrderByStartDate;
    [self configureFilter:self.filter withWeekRangeForDate:[NSDate date]];
    
    pendingRequests = [NSMutableArray array];
    self.topToolBar.backgroundColor = [UIColor sb_navigationBarColor];

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
    self.collectionView.collectionViewLayout = self.calendarGridLayout;

    self.prevWeekButton.transform = CGAffineTransformRotate(self.prevWeekButton.transform, M_PI);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    SBRequest *checkPluginRequest = [[SBSession defaultSession] isPluginActivated:kSBPluginRepositoryApproveBookingPlugin callback:^(SBResponse<NSNumber *> * _Nonnull response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryApproveBookingPlugin enabled:[response.result boolValue]];
            self.activityIndicator.hidden = YES;
            self.filter = [SBGetBookingsFilter todayBookingsFilter];
            self.filter.order = kSBGetBookingsFilterOrderByStartDate;
            [self configureFilter:self.filter withWeekRangeForDate:[NSDate date]];
            [self loadData];
        });
    }];
    self.activityIndicator.hidden = NO;
    [[SBSession defaultSession] performReqeust:checkPluginRequest];
}

- (void)loadData
{
    NSAssert(self.filter != nil, @"no filter");
    NSAssert(self.filter.from != nil, @"no date selected");

    SBSession *session = [SBSession defaultSession];
    [session cancelRequests:pendingRequests];
    NSAssert(session != nil, @"no active session");

    self.datesIntervalLabel.text = [self.dateIntervalFormatter stringFromDate:self.filter.from toDate:self.filter.to];

    SBRequestsGroup *group = [SBRequestsGroup new];

    __block NSInteger timeframeStep = 0;
    SBRequest *loadCompanyInfoRequest = [session getCompanyInfoWithCallback:^(SBResponse *response) {
        SBCompanyInfo *companyInfo = response.result;
        timeframeStep = [companyInfo.timeframe integerValue];
    }];
    [group addRequest:loadCompanyInfoRequest];

    __block NSDictionary *workingHours = nil;
    SBRequest *loadTimeFrameRequest = [session getWorkDaysTimesForStartDate:self.filter.from
                                                                    endDate:[self.filter.to nextDayDate]
                                                                   callback:^(SBResponse *response) {
                                                                       workingHours = response.result;
                                                                   }];
    [group addRequest:loadTimeFrameRequest];

    NSMutableArray *sections = [NSMutableArray array];
    NSCalendar *calendar = [NSDate sb_calendar];
    NSDateComponents *components = [NSDateComponents new];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEdM" options:0 locale:[NSLocale currentLocale]];
    for (NSInteger day = 0; day < 7; day++) {
        components.day = day + [calendar component:NSCalendarUnitDay fromDate:self.filter.from];
        components.month = [calendar component:NSCalendarUnitMonth fromDate:self.filter.from];
        components.year = [calendar component:NSCalendarUnitYear fromDate:self.filter.from];
        NSDate *date = [calendar dateFromComponents:components];
        components.day = 1;
        components.month = 0;
        components.year = 0;
        NSDate *nextDate = [calendar dateByAddingComponents:components toDate:date options:0];
        NSPredicate *sectionPredicate = [NSPredicate predicateWithBlock:^BOOL(SBBookingObject *booking, NSDictionary *bindings) {
            return [booking.startDate compare:date] >= NSOrderedSame && [booking.startDate compare:nextDate] == NSOrderedAscending;
        }];
        CalendarSectionDataSource *section = [[CalendarSectionDataSource alloc] initWithTitle:[dateFormatter stringFromDate:date]
                                                                                    predicate:sectionPredicate
                                                                        substitutionVariables:nil];
        section.sectionID = date;
        [sections addObject:section];
    }

    __block SBBookingStatusesCollection *statuses = nil;
    SBRequest *loadStatusesRequest = [session getStatusesList:^(SBResponse *response) {
        statuses = response.result;
    }];
    [group addRequest:loadStatusesRequest];

    __block NSArray <SBBooking *> *bookings = nil;
    SBRequest *loadBookingsRequest = [[SBSession defaultSession] getBookingsWithFilter:self.filter callback:^(SBResponse *response) {
        bookings = response.result;
    }];
    loadBookingsRequest.cachePolicy = SBIgnoreCachePolicy;
    [loadBookingsRequest addDependency:loadTimeFrameRequest];
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
                SBWorkingHoursMatrix *workingHoursMatrix = [[SBWorkingHoursMatrix alloc] initWithData:workingHours];
                [workingHoursMatrix updateDatesUsingBookingsInfo:bookings];
                [self.calendarGridLayout setWorkingHoursMatrix:workingHoursMatrix];
                [self.calendarDataSource setWorkingHoursMatrix:workingHoursMatrix];
                [self.calendarDataSource setSections:sections];
                [self.calendarDataSource setStatusesCollection:statuses];
                [self.calendarDataSource setBookings:bookings sortingStrategy:CalendarGridBookingsLayoutSortingStrategy];
                [self.collectionView reloadData];
                [self.collectionView.collectionViewLayout invalidateLayout];
                [self.collectionView setContentOffset:CGPointZero animated:YES];
            }
        });
    };
    self.activityIndicator.hidden = NO;
    [pendingRequests addObject:group.GUID];
    self.loading = YES;
    [session performReqeust:group];
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
    if ([calendar firstWeekday] == 2) { // first day of the week is Monday
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
    if (![self isLoading] || self.calendarDataSource.timeframeStep) {
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
    [self configureFilter:self.filter withWeekRangeForDate:[NSDate date]];
    [self loadData];
}

- (void)recognizeTapGesture:(UITapGestureRecognizer *)recognizer
{
    CGPoint position = [recognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.calendarGridLayout indexPathForCellAtPosition:position];
    if (indexPath) {
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
