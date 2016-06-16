//
//  AgendaViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "AgendaViewController.h"
#import "SBSession.h"
#import "AgendaDataSource.h"
#import "AgendaCollectionViewLayout.h"
#import "NSError+SimplyBook.h"
#import "SBRequestsGroup.h"
#import "BookingDetailsViewController.h"
#import "SBCache.h"
#import "SBGetBookingsRequest.h"
#import "LSManagedObjectContext.h"
#import "SBReachability.h"
#import "SBSessionManager.h"

@interface AgendaViewController () <SBSessionManagerDelegateObserver>
{
    NSMutableArray <NSString *> *pendingRequests;
    AgendaDataSource *dataSource;
    SBRequest *getBookingsRequest;
    BOOL isLoading;
}

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSTimer *updatesTimer;

@end

@implementation AgendaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    pendingRequests = [NSMutableArray array];
    dataSource = [[AgendaDataSource alloc] init];
    [dataSource configureCollectionView:self.collectionView];
    self.collectionView.collectionViewLayout = [AgendaCollectionViewLayout new];
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    
    [[SBSessionManager sharedManager] addObserver:self];
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
    
    SBReachability *reach = [SBReachability reachabilityWithHostName:kSBReachabilityHostname];
    reach.reachabilityBlock = ^(SBReachability * reachability, SCNetworkConnectionFlags flags) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (flags & kSCNetworkFlagsReachable) {
                if (!getBookingsRequest) {
                    [self loadData];
                }
                [(AgendaCollectionViewLayout *)self.collectionView.collectionViewLayout setNoConnection:NO];
                self.navigationItem.rightBarButtonItem.enabled = YES;
            } else {
                self.navigationItem.rightBarButtonItem.enabled = NO;
                [(AgendaCollectionViewLayout *)self.collectionView.collectionViewLayout setNoConnection:YES];
            }
        });
    };
    [reach startNotifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadData
{
    SBRequestsGroup *group = [SBRequestsGroup new];
    
    __block SBPerformersCollection *performers = nil;
    SBRequest *getPerformersRequest = [[SBSession defaultSession] getUnitList:^(SBResponse<SBPerformersCollection *> * _Nonnull response) {
        if (!response.error && ![response isKindOfClass:[SBCachedResponse class]]) {
            performers = response.result;
        }
    }];
    [group addRequest:getPerformersRequest];
    
    __block NSArray <SBBooking *> *bookings = nil;
    getBookingsRequest = [[SBSession defaultSession] getBookingsWithFilter:dataSource.filter callback:^(SBResponse<id> * _Nonnull response) {
        if (!response.error) {
            bookings = response.result;
        }
    }];
    [group addRequest:getBookingsRequest];
    
    __block SBBookingStatusesCollection *statuses = nil;
    SBRequest *getStatusesRequest = [[SBSession defaultSession] getStatusesList:^(SBResponse<SBBookingStatusesCollection *> * _Nonnull response) {
        if (!response.error) {
            statuses = response.result;
        }
    }];
    [group addRequest:getStatusesRequest];
    
    group.callback = ^(SBResponse *response) {
        [pendingRequests removeObject:response.requestGUID];
        dispatch_async(dispatch_get_main_queue(), ^{
            isLoading = NO;
            [self.activityIndicator stopAnimating];
            [self.refreshControl endRefreshing];
            if (!response.error) {
                if (performers) {
                    [dataSource setPerformers:performers];
                }
                if (statuses) {
                    [dataSource setStatuses:statuses];
                }
                [dataSource addBookings:bookings];
                [self.collectionView reloadData];
            } else if ([response.error isNetworkConnectionError]) {
                self.navigationItem.rightBarButtonItem.enabled = NO;
                [(AgendaCollectionViewLayout *)self.collectionView.collectionViewLayout setNoConnection:YES];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLS(@"Error",@"")
                                                                               message:[response.error message]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLS(@"OK",@"")
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
            [self.updatesTimer invalidate];
            self.updatesTimer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(updatesTimerHandler:) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:self.updatesTimer forMode:NSRunLoopCommonModes];
        });
    };
    
    [self.activityIndicator startAnimating];
    [pendingRequests addObject:group.GUID];
    isLoading = YES;
    [[SBSession defaultSession] performReqeust:group];
}

- (IBAction)refreshAction:(id)sender
{
    [[SBCache cache] invalidateCacheForRequest:getBookingsRequest];
    [self loadData];
}

- (void)updatesTimerHandler:(NSTimer *)timer
{
    [[SBCache cache] invalidateCacheForRequest:getBookingsRequest];
    [self loadData];
}

- (void)didInvalidateCacheNotificationHandler:(NSNotification *)notification
{
    if (isLoading) {
        return;
    }
    if ((notification.userInfo[kSBCache_RequestObjectUserInfoKey] && [notification.userInfo[kSBCache_RequestObjectUserInfoKey] isKindOfClass:[SBGetBookingsRequest class]])
        || (notification.userInfo[kSBCache_RequestClassUserInfoKey] && [notification.userInfo[kSBCache_RequestClassUserInfoKey] isSubclassOfClass:[SBGetBookingsRequest class]])
        || [notification.name isEqualToString:kSBCache_DidInvalidateCacheNotification]) {
        [self loadData];
    }
}

#pragma mark -

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self performSegueWithIdentifier:@"showBookingDetails-iPad" sender:self];
    }
    else {
        [self performSegueWithIdentifier:@"showBookingDetails" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showBookingDetails"]
            || [segue.identifier isEqualToString:@"showBookingDetails-iPad"]) {
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        NSAssert(indexPath != nil, @"no selected bookings");
        SBBooking *booking = (SBBooking *) [dataSource bookingAtIndexPath:indexPath];
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
}

#pragma mark - SBSessionManager delegate

- (void)sessionManager:(SBSessionManager *)manager willEndSession:(SBSession *)session
{
    if (pendingRequests.count) {
        [[SBSession defaultSession] cancelRequests:pendingRequests];
    }
    if (self.updatesTimer) {
        [self.updatesTimer invalidate];
        self.updatesTimer = nil;
    }
    [manager removeObserver:self];
}

- (void)sessionManager:(SBSessionManager *)manager didStartSession:(SBSession *)session
{
}

- (void)sessionManager:(SBSessionManager *)manager didEndSessionForCompany:(NSString *)companyLogin user:(NSString *)userLogin
{
}

- (void)sessionManager:(SBSessionManager *)manager didFailStartSessionWithError:(NSError *)error
{
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
