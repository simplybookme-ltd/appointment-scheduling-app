//
//  BookingsListViewController.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 30.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "BookingsListViewController.h"
#import "CalendarSectionDataSource.h"
#import "SBWorkingHoursMatrix.h"
#import "CalendarDataSource.h"
#import "BookingDetailsViewController.h"
#import "SBBookingStatusesCollection.h"

@interface BookingsListViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak, nullable) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong, nonnull) CalendarDataSource *dataSource;
@property (nonatomic, weak, nullable) IBOutlet UICollectionViewFlowLayout *flowLayout;

@end

@implementation BookingsListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSAssert(self.bookings.count > 0, @"there is no sence to create booking list with no bookings");
    NSAssert(self.timeframeStep > 0, @"timeframe step not set");
    self.bookings = [self.bookings sortedArrayUsingComparator:^NSComparisonResult(SBBookingObject *obj1, SBBookingObject *obj2) {
        return [obj1.startDate compare:obj2.startDate];
    }];
    SBWorkingHoursMatrix *workingHoursMatrix = [[SBWorkingHoursMatrix alloc] initWithStartDate:self.bookings.firstObject.startDate
                                                                                       endDate:self.bookings.lastObject.endDate
                                                                                          step:self.timeframeStep];

    NSDateFormatter *timeFormatter = [NSDateFormatter new];
    timeFormatter.timeStyle = NSDateFormatterNoStyle;
    timeFormatter.dateStyle = NSDateFormatterLongStyle;
    self.title = [timeFormatter stringFromDate:self.bookings.firstObject.startDate];
    timeFormatter.dateStyle = NSDateFormatterNoStyle;
    timeFormatter.timeStyle = NSDateFormatterShortStyle;

    NSMutableArray <CalendarSectionDataSource *> *sections = [NSMutableArray array];
    __block CalendarSectionDataSource *section = nil;
    __block NSDate *lastDate = nil;
    [self.bookings enumerateObjectsUsingBlock:^(SBBookingObject *booking, NSUInteger idx, BOOL *stop) {
        if (!section || [lastDate compare:booking.startDate] != NSOrderedSame) {
            NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SBBookingObject *bookingObject, NSDictionary *bindings) {
                return [bookingObject.startDate compare:bindings[@"startDate"]] == NSOrderedSame;
            }];
            section = [[CalendarSectionDataSource alloc] initWithTitle:[timeFormatter stringFromDate:booking.startDate]
                                                             predicate:predicate
                                                 substitutionVariables:@{@"startDate" : booking.startDate}];
            [sections addObject:section];
        }
        lastDate = booking.startDate;
    }];

    self.dataSource = [CalendarDataSource new];
    self.dataSource.timeframeStep = self.timeframeStep;
    self.dataSource.sections = sections;
    if (self.statuses) {
        [self.dataSource setStatusesCollection:self.statuses];
    }
    [self.dataSource configureCollectionView:self.collectionView];
    [self.dataSource setBookings:self.bookings sortingStrategy:nil];
    self.dataSource.workingHoursMatrix = workingHoursMatrix;

    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLS(@"Close", @"")
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self action:@selector(backAction:)];
    }
}

#pragma mark -

- (void)backAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.dataSource.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSParameterAssert(section < self.dataSource.sections.count);
    return self.dataSource.sections[section].items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.dataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                              withReuseIdentifier:@"time-header"
                                                                                     forIndexPath:indexPath];
        UILabel *timeLabel = (UILabel *)[header viewWithTag:100];
        CalendarSectionDataSource *section = self.dataSource.sections[indexPath.section];
        timeLabel.text = section.title;
        return header;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.frame.size.width - self.flowLayout.sectionInset.left - self.flowLayout.sectionInset.right,
            self.flowLayout.itemSize.height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showBookingDetails" sender:self];
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showBookingDetails"]) {
        NSIndexPath *indexPath = [self.collectionView indexPathsForSelectedItems].firstObject;
        SBBooking *booking = (SBBooking *)[self.dataSource bookingAtIndexPath:indexPath];
        NSAssert(booking != nil, @"no booking selected");
        BookingDetailsViewController *controller = segue.destinationViewController;
        controller.bookingID = booking.bookingID;
        controller.clientName = booking.clientName;
        controller.clientEmail = booking.clientEmail;
        controller.clientPhone = booking.clientPhone;
        controller.onBookingCanceledHandler = ^(NSString *bookingID) {
        };
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}

@end
