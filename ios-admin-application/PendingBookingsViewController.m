//
//  PendingBookingsViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "PendingBookingsViewController.h"
#import "SBSession.h"
#import "SBPluginsRepository.h"
#import "NSError+SimplyBook.h"
#import "PendingBookingCollectionViewCell.h"
#import "PendingBookingsCollectionViewLayout.h"
#import "BookingDetailsViewController.h"

@interface PendingBookingsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    NSMutableArray *pendingRequests;
    NSMutableArray *pendingBookings;
}

@property (nonatomic, weak, nullable) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak, nullable) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak, nullable) IBOutlet UIView *pluginNotAvailableView;
@property (nonatomic, weak, nullable) IBOutlet UILabel *noPendingBookingsLabel;
@property (nonatomic, strong, nullable) NSMutableArray <NSDictionary <NSString *, id> *> *bookings;
@property (nonatomic, strong, nonnull) NSDateIntervalFormatter *intervalFormatter;

@end

@implementation PendingBookingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    pendingRequests = [NSMutableArray array];
    pendingBookings = [NSMutableArray array];
    self.pluginNotAvailableView.hidden = YES;
    self.collectionView.hidden = YES;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"PendingBookingCollectionViewCell" bundle:nil]
          forCellWithReuseIdentifier:@"pending-booking-cell"];
    NSAssert([self.collectionView.collectionViewLayout isKindOfClass:[PendingBookingsCollectionViewLayout class]],
             @"unexpected collection view layout. %@ expected but %@ occurred.",
             NSStringFromClass([PendingBookingsCollectionViewLayout class]), NSStringFromClass([self.collectionView.collectionViewLayout class]));
    ((PendingBookingsCollectionViewLayout *)self.collectionView.collectionViewLayout).pendingBookingsDataSource = self;

    SBRequest *request = [[SBSession defaultSession] isPluginActivated:kSBPluginRepositoryApproveBookingPlugin callback:^(SBResponse<NSNumber *> * _Nonnull response) {
        [pendingRequests removeObject:response.requestGUID];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (response.error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"") message:response.error.message
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles:nil];
                [alert show];
                [self.activityIndicator stopAnimating];
                self.collectionView.hidden = YES;
                self.pluginNotAvailableView.hidden = NO;
                @synchronized (self) {
                    self.bookings = nil;
                }
            }
            else {
                if (response.result.boolValue) {
                    [self loadPendingBookings];
                } else {
                    [self.activityIndicator stopAnimating];
                    self.collectionView.hidden = YES;
                    self.pluginNotAvailableView.hidden = NO;
                    @synchronized (self) {
                        self.bookings = nil;
                    }
                }
            }
        });
    }];
    [pendingRequests addObject:request.GUID];
    [self.activityIndicator startAnimating];
    [[SBSession defaultSession] performReqeust:request];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pendingBookingsDidUpdateNotificationHandler:)
                                                 name:kSBPendingBookings_DidUpdateNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSBPendingBookings_DidUpdateNotification
                                                  object:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (nonnull NSDateIntervalFormatter *)intervalFormatter
{
    if (_intervalFormatter) {
        return _intervalFormatter;
    }
    _intervalFormatter = [NSDateIntervalFormatter new];
    [_intervalFormatter setDateStyle:NSDateIntervalFormatterShortStyle];
    [_intervalFormatter setTimeStyle:NSDateIntervalFormatterShortStyle];
    return _intervalFormatter;
}

- (void)didUpdateNumberOfPendingBookings
{
    self.noPendingBookingsLabel.hidden = (self.bookings.count != 0);
    if (self.bookings.count > 0) {
        self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.bookings.count];
    }
    else {
        self.navigationController.tabBarItem.badgeValue = nil;
    }
}

- (void)pendingBookingsDidUpdateNotificationHandler:(NSNotification *)notification
{
    if (notification.object != self) {
        [self loadPendingBookings];
    }
}

#pragma mark - Requests

- (void)approveBookingWithID:(NSString *)bookingID
{
    // use dispatch async to sync pendingBookings array content
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setBookingWithID:bookingID approved:YES errorMessage:NSLS(@"An error occurred during approving booking. Please try again later.",@"")];
    });
}

- (void)cancelBookingWithID:(NSString *)bookingID
{
    // use dispatch async to sync pendingBookings array content
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setBookingWithID:bookingID approved:NO errorMessage:NSLS(@"An error occurred during booking cancellation. Please try again later.",@"")];
    });
}

- (void)setBookingWithID:(NSString *)bookingID approved:(BOOL)approved errorMessage:(NSString *)errorMessage
{
    NSParameterAssert(bookingID != nil && ![bookingID isEqualToString:@""]);
    if ([pendingBookings containsObject:bookingID]) {
        return;
    }
    SBRequest *request = [[SBSession defaultSession] setBookingApproved:YES bookingID:bookingID callback:^(SBResponse<id> * _Nonnull response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [pendingRequests removeObject:response.requestGUID];
            [pendingBookings removeObject:bookingID];
            NSUInteger idx = [self.bookings indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj[@"id"] isEqualToString:bookingID];
            }];
            if (!response.error) {
                if (idx != NSNotFound && idx < self.bookings.count) {
                    @synchronized (self) {
                        [self.bookings removeObjectAtIndex:idx];
                    }
                    [self.collectionView.collectionViewLayout invalidateLayout];
                    [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:idx inSection:0]]];
                } else {
                    [self.collectionView reloadData];
                }
                [self didUpdateNumberOfPendingBookings];
                SBRequest *getPendingBookingsRequest = [[SBSession defaultSession] getPendingBookingsWithCallback:nil];
                [[SBCache cache] invalidateCacheForRequest:getPendingBookingsRequest];
                [[NSNotificationCenter defaultCenter] postNotificationName:kSBPendingBookings_DidUpdateNotification
                                                                    object:self
                                                                  userInfo:@{kSBPendingBookings_BookingIDKey: bookingID}];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"")
                                                                message:errorMessage
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles:nil];
                [alert show];
                if (idx != NSNotFound) {
                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:idx inSection:0]]];
                }
            }
        });
    }];
    [pendingBookings addObject:bookingID];
    [pendingRequests addObject:request.GUID];
    [[SBSession defaultSession] performReqeust:request];
}

- (void)loadPendingBookings
{
    SBRequest *request = [[SBSession defaultSession] getPendingBookingsWithCallback:^(SBResponse<NSArray *> * _Nonnull response) {
        [pendingRequests removeObject:response.requestGUID];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (response.error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLS(@"Error",@"") message:response.error.message
                                                               delegate:nil cancelButtonTitle:NSLS(@"OK",@"") otherButtonTitles:nil];
                [alert show];
                @synchronized (self) {
                    self.bookings = nil;
                }
            }
            else {
                NSUInteger pendingBookingsCount = (self.bookings ? self.bookings.count : NSNotFound);
                @synchronized (self) {
                    self.bookings = [NSMutableArray arrayWithArray:[response.result sortedArrayUsingComparator:^NSComparisonResult(NSDictionary * _Nonnull obj1, NSDictionary * _Nonnull obj2) {
                        return [obj1[@"start_date"] compare:obj2[@"start_date"]];
                    }]];
                }
                if (pendingBookingsCount != self.bookings.count) {
                    [self didUpdateNumberOfPendingBookings];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSBPendingBookings_DidUpdateNotification
                                                                        object:self
                                                                      userInfo:@{kSBPendingBookings_BookingsCountKey: @(self.bookings.count)}];
                }
            }
            self.collectionView.hidden = NO;
            [self.activityIndicator stopAnimating];
            [self.collectionView reloadData];
        });
    }];
    [pendingRequests addObject:request.GUID];
    [self.activityIndicator startAnimating];
    [[SBSession defaultSession] performReqeust:request];
}

#pragma mark - Actions

- (IBAction)enablePluginAction:(id)sender
{
    NSString *URLString = [NSString stringWithFormat:@"https://%@.secure.simplybook.me/settings/plugins", [SBSession defaultSession].user.credentials.companyLogin];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.bookings.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PendingBookingCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"pending-booking-cell" forIndexPath:indexPath];
    NSDictionary *booking = self.bookings[indexPath.item];
    NSString *bookingID = [booking[@"id"] copy];
    cell.timeLabel.text = [self.intervalFormatter stringFromDate:booking[@"start_date"] toDate:booking[@"end_date"]];
    cell.serviceLabel.text = booking[@"event_name"];
    cell.performerLabel.text = booking[@"unit_name"];
    cell.clientLabel.text = [NSString stringWithFormat:NSLS(@"Client: %1$@\nPhone: %2$@\nEmail: %3$@",@"approve bookings list cell"),
                             booking[@"client"], booking[@"client_phone"], booking[@"client_email"]];
    cell.action = ^(PendingBookingCollectionViewCell *_cell, PendingBookingAction action) {
        [[self.collectionView indexPathsForSelectedItems] enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj isEqual:indexPath]) {
                [self.collectionView deselectItemAtIndexPath:obj animated:NO];
            }
        }];
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        switch (action) {
            case PendingBookingShowOptionsAction:
                [_cell showOptions];
                break;
            case PendingBookingApproveAction:
                [_cell hideOptions];
                [self approveBookingWithID:bookingID];
                [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                break;
            case PendingBookingCancelAction:
                [_cell hideOptions];
                [self cancelBookingWithID:bookingID];
                [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                break;
            case PendingBookingViewAction:
                [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    [self performSegueWithIdentifier:@"showBookingDetails-iPad" sender:self];
                }
                else {
                    [self performSegueWithIdentifier:@"showBookingDetails" sender:self];
                }
                break;
                
            default:
                break;
        }
    };
    if ([pendingBookings containsObject:bookingID]) {
        [cell showActivityIndicator];
    }
    else {
        [cell hideActivityIndicator];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        return CGSizeMake(self.collectionView.frame.size.width, 135);
    }
    return CGSizeMake(self.collectionView.frame.size.width / 2., 135);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PendingBookingCollectionViewCell *cell = (PendingBookingCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [cell showOptions];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self performSegueWithIdentifier:@"showBookingDetails-iPad" sender:self];
    }
    else {
        [self performSegueWithIdentifier:@"showBookingDetails" sender:self];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showBookingDetails-iPad"]
        || [segue.identifier isEqualToString:@"showBookingDetails"])
    {
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
        NSAssert(indexPath != nil, @"no selected bookings");
        NSDictionary *booking = self.bookings[indexPath.item];
        BookingDetailsViewController *controller = nil;
        if ([segue.identifier isEqualToString:@"showBookingDetails"]) {
            controller = segue.destinationViewController;
        }
        else if ([segue.identifier isEqualToString:@"showBookingDetails-iPad"]) {
            NSAssert([segue.destinationViewController isKindOfClass:[UINavigationController class]], @"unexpected view controllers hierarchy");
            controller = (BookingDetailsViewController *) [(UINavigationController *) segue.destinationViewController topViewController];
        }
        controller.bookingID = booking[@"id"];
        controller.clientName = booking[@"client"];
        controller.clientEmail = booking[@"client_email"];
        controller.clientPhone = booking[@"client_phone"];
    }
}

@end
