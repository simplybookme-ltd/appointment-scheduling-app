//
//  AgendaDataSource.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "AgendaDataSource.h"
#import "NSDate+TimeManipulation.h"
#import "UIColor+SimplyBookColors.h"
#import "BookingCollectionViewCell.h"
#import "TextCollectionReusableView.h"
#import "AgendaCollectionViewLayout.h"
#import "LSManagedObjectContext.h"
#import "LSBooking.h"
#import "LSBooking+CoreDataProperties.h"
#import "LSPerformer.h"
#import "LSPerformer+CoreDataProperties.h"
#import "LSBookingStatus.h"
#import "LSBooking+CoreDataProperties.h"
#import "SBSession.h"
#import "SBUser.h"

@interface AgendaSectionDataSource : NSObject

@property (nonatomic, strong) NSMutableArray <LSBooking *> *bookings;
@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, strong) NSDate *date;

- (instancetype)initForDate:(NSDate *)date performers:(SBPerformersCollection *)performers;
- (SBBooking *)bookingAtIndex:(NSInteger)index;

@end

@interface AgendaDataSource () {
    NSArray <LSBooking *> *rawBookings;
    NSMutableDictionary <NSDate *, AgendaSectionDataSource *> *sections;
    NSArray *orderedSections;
    SBMutableCollection <SBPerformer *> *performers;
    NSArray *statuses;
    SBBookingStatus *defaultStatus;
}

@property (nonatomic, readwrite, strong) NSCalendar *calendar;
@property (nonatomic, readwrite, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateIntervalFormatter *intervalFormatter;
@property (nonatomic, readwrite, strong) SBGetBookingsFilter *filter;
@property (nonatomic, strong) LSManagedObjectContext *managedObjectContext;

@end

@implementation AgendaDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotificationHandler:)
                                                     name:NSManagedObjectContextDidSaveNotification object:nil];
        sections = [NSMutableDictionary dictionary];
        orderedSections = [NSArray array];
        performers = [[SBMutableCollection alloc] init];
        NSArray *storedPerformers = [self.managedObjectContext fetchObjectOfEntity:NSStringFromClass([LSPerformer class]) withPredicate:nil error:nil];
        for (SBPerformer *performer in storedPerformers) {
            [performers addObject:performer];
        }
        statuses = [self.managedObjectContext fetchObjectOfEntity:NSStringFromClass([LSBookingStatus class]) withPredicate:nil error:nil];
        [statuses enumerateObjectsUsingBlock:^(SBBookingStatus * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.isDefault) {
                defaultStatus = obj;
                *stop = YES;
            }
        }];
        [self loadBookings];
        [self reorderSections];
    }
    return self;
}

- (NSCalendar *)calendar
{
    if (!_calendar) {
        _calendar = [NSCalendar currentCalendar];
    }
    return _calendar;
}

- (nonnull NSDateIntervalFormatter *)intervalFormatter
{
    if (_intervalFormatter) {
        return _intervalFormatter;
    }
    _intervalFormatter = [NSDateIntervalFormatter new];
    [_intervalFormatter setDateStyle:NSDateIntervalFormatterNoStyle];
    [_intervalFormatter setTimeStyle:NSDateIntervalFormatterShortStyle];
    return _intervalFormatter;
}

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter) {
        return _dateFormatter;
    }
    _dateFormatter = [NSDateFormatter new];
    _dateFormatter.dateStyle = NSDateFormatterLongStyle;
    _dateFormatter.doesRelativeDateFormatting = YES;
    _dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    return _dateFormatter;
}

- (SBGetBookingsFilter *)filter
{
    if (!_filter) {
        _filter = [SBGetBookingsFilter todayBookingsFilter];
        NSDateComponents *components = [NSDateComponents new];
        components.day = 7;
        _filter.to = [self.calendar dateByAddingComponents:components toDate:_filter.from options:0];
        SBUser *user = [SBSession defaultSession].user;
        NSAssert(user != nil, @"no user found");
        if (![user hasAccessToACLRule:SBACLRulePerformersFullListAccess]) {
            NSAssert(user.associatedPerformerID != nil && ![user.associatedPerformerID isEqualToString:@""], @"invalid associated performer value");
            _filter.unitGroupID = user.associatedPerformerID;
        }
    }
    return _filter;
}

- (LSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = [[LSManagedObjectContext alloc] init];
    }
    return _managedObjectContext;
}

#pragma mark -

- (LSPerformer *)storedPerformerWithID:(NSString *)performerID
{
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext fetchObjectOfEntity:NSStringFromClass([LSPerformer class])
                                                        withPredicate:[NSPredicate predicateWithFormat:@"searchID = %@", @([performerID integerValue])]
                                                                error:&error];
    return objects.firstObject;
}

- (void)savePerformer:(SBPerformer *)performer
{
    NSParameterAssert(performer != nil);
    LSPerformer *stored = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([LSPerformer class])
                                                        inManagedObjectContext:self.managedObjectContext];
    stored.performerID = performer.performerID;
    stored.searchID = @(performer.performerID.integerValue);
    [self updateStoredPerformer:stored withDataOfPerformer:performer];
}

- (void)updateStoredPerformer:(LSPerformer *)stored withDataOfPerformer:(SBPerformer *)performer
{
    NSParameterAssert(stored != nil);
    NSParameterAssert(performer != nil);
    NSParameterAssert([stored.performerID isEqualToString:performer.performerID]);
    stored.name = performer.name;
    stored.performerDescription = performer.performerDescription;
    stored.email = performer.email;
    stored.phone = performer.phone;
    stored.picture = performer.picture;
    stored.picturePath = performer.picturePath;
    stored.position = performer.position;
    stored.color = performer.color;
    stored.isActive = performer.isActive;
    stored.isVisible = performer.isVisible;
    stored.lastUpdate = [NSDate date];
}

- (LSBookingStatus *)storedBookingStatusWithID:(NSString *)statusID
{
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext fetchObjectOfEntity:NSStringFromClass([LSBookingStatus class])
                                                        withPredicate:[NSPredicate predicateWithFormat:@"searchID = %@", @([statusID integerValue])]
                                                                error:&error];
    return objects.firstObject;
}

- (void)saveBookingStatus:(SBBookingStatus *)status
{
    NSParameterAssert(status != nil);
    LSBookingStatus *stored = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([LSBookingStatus class])
                                                            inManagedObjectContext:self.managedObjectContext];
    stored.statusID = status.statusID;
    stored.searchID = @(status.statusID.integerValue);
    [self updateStoredBookingStatus:stored withDataOfBookingStatus:status];
}

- (void)updateStoredBookingStatus:(LSBookingStatus *)stored withDataOfBookingStatus:(SBBookingStatus *)status
{
    NSParameterAssert(stored != nil);
    NSParameterAssert(status != nil);
    NSParameterAssert([stored.statusID isEqualToString:status.statusID]);
    stored.name = status.name;
    stored.isDefault = @(status.isDefault);
    stored.hexColor = status.HEXColor;
    stored.lastUpdate = [NSDate date];
}

- (LSBooking *)storedBookingWithID:(NSString *)bookingID
{
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext fetchObjectOfEntity:NSStringFromClass([LSBooking class])
                                                        withPredicate:[NSPredicate predicateWithFormat:@"searchID = %@", @([bookingID integerValue])]
                                                                error:&error];
    return objects.firstObject;
}

- (void)saveBooking:(SBBooking *)booking
{
    NSParameterAssert(booking != nil);
    LSBooking *stored = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([LSBooking class])
                                                      inManagedObjectContext:self.managedObjectContext];
    stored.searchID = @(booking.bookingID.integerValue);
    stored.bookingID = booking.bookingID;
    [self updateStoredBooking:stored withDataOfBooking:booking];
}

- (void)updateStoredBooking:(LSBooking *)stored withDataOfBooking:(SBBooking *)booking
{
    NSParameterAssert(booking != nil);
    NSParameterAssert(stored != nil);
    NSParameterAssert([stored.bookingID isEqualToString:booking.bookingID]);
    stored.lastUpdate = [NSDate date];
    stored.clientEmail = booking.clientEmail;
    stored.clientID = booking.clientID;
    stored.clientName = booking.clientName;
    stored.clientPhone = booking.clientPhone;
    stored.endDate = booking.endDate;
    stored.eventTitle = booking.eventTitle;
    stored.isConfirmed = booking.isConfirmed;
    stored.paymentStatus = booking.paymentStatus;
    stored.paymentSystem = booking.paymentSystem;
    stored.performerID = booking.performerID;
    stored.performerName = booking.performerName;
    stored.recordDate = booking.recordDate;
    stored.startDate = booking.startDate;
    stored.statusID = booking.statusID;
}

- (NSArray *)fetchBookings
{
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([LSBooking class]) inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"startDate >= %@ AND endDate <= %@", [self.filter.from dateWithZeroTime], [self.filter.to dateWithZeroTime]]];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]]];
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
}

- (void)loadBookings
{
    rawBookings = [self fetchBookings];
}

- (void)saveContext
{
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    if (error) {
        NSAssert(NO, @"%@", error);
    }
}

#pragma mark -

- (void)contextDidSaveNotificationHandler:(NSNotification *)notification
{
    if ([notification.object isKindOfClass:[LSManagedObjectContext class]]) {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
        [self loadBookings];
    }
}

#pragma mark -

- (void)setPerformers:(SBPerformersCollection *)_performers
{
    [_performers enumerateUsingBlock:^(NSString * _Nonnull objectID, SBPerformer * _Nonnull performer, BOOL * _Nonnull stop) {
        LSPerformer *storedPerformer = [self storedPerformerWithID:performer.performerID];
        if (!storedPerformer) {
            [self savePerformer:performer];
        } else {
            [self updateStoredPerformer:storedPerformer withDataOfPerformer:performer];
        }
    }];
    
    [self saveContext];
    if (rawBookings.count > 0) {
        [self reorderSections];
    }
}

- (void)addBookings:(NSArray<SBBooking *> *)bookings
{
    NSMutableArray<NSString *> *ids = [NSMutableArray array];
    for (SBBooking *booking in bookings) {
        [ids addObject:booking.bookingID];
    }
    NSArray *storedBookings = [self fetchBookings];
    for (LSBooking *stored in storedBookings) {
        if (![ids containsObject:stored.bookingID]) {
            [self.managedObjectContext deleteObject:stored];
        }
    }
    for (SBBooking *booking in bookings) {
        LSBooking *stored = [self storedBookingWithID:booking.bookingID];
        if (!stored) {
            [self saveBooking:booking];
        } else {
            [self updateStoredBooking:stored withDataOfBooking:booking];
        }
    }
    [self saveContext];
    
    [self loadBookings];
    if (performers) {
        [self reorderSections];
    }
}

- (void)setStatuses:(SBBookingStatusesCollection *)_statuses
{
    statuses = [_statuses allObjects];
    defaultStatus = _statuses.defaultStatus;
    for (SBBookingStatus *status in statuses) {
        LSBookingStatus *stored = [self storedBookingStatusWithID:status.statusID];
        if (!stored) {
            [self saveBookingStatus:status];
        } else {
            [self updateStoredBookingStatus:stored withDataOfBookingStatus:status];
        }
    }
    [self saveContext];
}

- (SBBooking *)bookingAtIndexPath:(NSIndexPath *)indexPath
{
    return [sections[orderedSections[indexPath.section]] bookingAtIndex:indexPath.item];
}

- (void)reorderSections
{
    sections = [NSMutableDictionary dictionary];
    NSDate *start = [self.filter.from dateWithZeroTime];
    NSDate *to = [self.filter.to dateWithZeroTime];
    NSDateComponents *components = [NSDateComponents new];
    components.day = 1;
    while ([start compare:to] < NSOrderedSame) {
        sections[start] = [[AgendaSectionDataSource alloc] initForDate:start performers:nil];
        start = [self.calendar dateByAddingComponents:components toDate:start options:0];
    }
    orderedSections = [sections.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    for (LSBooking *booking in rawBookings) {
        NSDate *key = [booking.startDate dateWithZeroTime];
        if (!sections[key]) {
            sections[key] = [[AgendaSectionDataSource alloc] initForDate:key performers:nil];
        }
        AgendaSectionDataSource *section = sections[key];
        [section.bookings addObject:booking];
    }
}

- (void)configureCollectionView:(UICollectionView *)collectionView
{
    collectionView.dataSource = self;
    [collectionView registerNib:[UINib nibWithNibName:@"BookingCollectionViewCell" bundle:nil]
     forCellWithReuseIdentifier:@"cell"];
    [collectionView registerNib:[UINib nibWithNibName:@"TextCollectionReusableView" bundle:nil]
     forSupplementaryViewOfKind:kAgendaHeaderSupplementaryElementKind withReuseIdentifier:@"header"];
    [collectionView registerNib:[UINib nibWithNibName:@"TextCollectionReusableView" bundle:nil]
     forSupplementaryViewOfKind:kAgendaNoDataSupplementaryElementKind withReuseIdentifier:@"nodata"];
    [collectionView registerNib:[UINib nibWithNibName:@"TextCollectionReusableView" bundle:nil]
     forSupplementaryViewOfKind:kAgendaNoConnectionSupplementaryElementKind withReuseIdentifier:@"noconnection"];
}

- (SBBookingStatus *)statusForID:(NSString *)statusID
{
    if (statusID) {
        NSUInteger idx = [statuses indexOfObjectPassingTest:^BOOL(SBBookingStatus * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.statusID isEqualToString:statusID];
        }];
        if (idx != NSNotFound) {
            return statuses[idx];
        }
    }
    return defaultStatus;
}

#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return orderedSections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return sections[orderedSections[section]].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                          cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BookingCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    SBBooking *booking = [self bookingAtIndexPath:indexPath];
    NSAssert(booking != nil, @"no booking for indexPath: %@", indexPath);
    UIColor *bgColor = [UIColor sb_defaultBookingColor];
    SBPerformer *performer = performers[booking.performerID];
    if (performer.color) {
        bgColor = [UIColor colorFromHEXString:performer.color];
    }
    SBBookingStatus *status = [self statusForID:booking.statusID];
    if (status && [status isKindOfClass:[SBBookingStatus class]]) {
        bgColor = [UIColor colorFromHEXString:status.HEXColor];
    } else if (status && [status isKindOfClass:[LSBookingStatus class]]) {
        bgColor = [UIColor colorFromHEXString:((LSBookingStatus *)status).hexColor];
    }
    UIColor *statusColor = nil;
    if (booking.paymentStatus) {
        if ([booking.paymentStatus isEqualToString:@"paid"] && [booking.paymentSystem isEqualToString:@"delay"]) {
            statusColor = [UIColor colorWithRed:1. green:221./255. blue:85./255. alpha:1];
        }
        else if (![booking.paymentStatus isEqualToString:@"paid"]) {
            statusColor = [UIColor redColor];
        }
    }
    [cell setBookingColor:bgColor canceled:![booking.isConfirmed boolValue]]; /// set color before text!
    [cell setTimeText:[self.intervalFormatter stringFromDate:booking.startDate toDate:booking.endDate]
               client:booking.clientName performer:booking.performerName setvice:booking.eventTitle
           stausColor:statusColor];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
                   viewForSupplementaryElementOfKind:(NSString *)kind
                                         atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:kAgendaHeaderSupplementaryElementKind]) {
        TextCollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        view.backgroundColor = [UIColor colorWithWhite:.95 alpha:1];
        AgendaSectionDataSource *section = sections[orderedSections[indexPath.section]];
        self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
        view.textLabel.text = [self.dateFormatter stringFromDate:section.date];
        view.textLabel.textColor = [UIColor blackColor];
        return view;
    }
    else if ([kind isEqualToString:kAgendaNoDataSupplementaryElementKind]) {
        TextCollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"nodata" forIndexPath:indexPath];
        view.textLabel.text = NSLS(@"No bookings", @"");
        view.textLabel.textColor = [UIColor lightGrayColor];
        return view;
    }
    else if ([kind isEqualToString:kAgendaNoConnectionSupplementaryElementKind]) {
        TextCollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"noconnection" forIndexPath:indexPath];
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:15.],
                                     NSForegroundColorAttributeName: [UIColor blackColor]};
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:NSLS(@"No internel connection",@"") attributes:attributes];
        if (rawBookings && rawBookings.count) {
            LSBooking *booking = rawBookings.firstObject;
            attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:13.],
                           NSForegroundColorAttributeName: [UIColor darkGrayColor]};
            self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
            [str appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@ %@", NSLS(@"Last updated: ", @""), [self.dateFormatter stringFromDate:booking.lastUpdate]]
                                                                        attributes:attributes]];
        }
        view.textLabel.numberOfLines = 2;
        view.textLabel.attributedText = str;
        view.backgroundColor = [UIColor colorWithRed:0.960 green:0.838 blue:0.247 alpha:0.900];
        return view;
    }
    return nil;
}

@end

#pragma mark -

@implementation AgendaSectionDataSource

- (instancetype)initForDate:(NSDate *)date performers:(SBPerformersCollection *)performers
{
    NSParameterAssert(date != nil);
    self = [super init];
    if (self) {
        self.date = date;
        self.bookings = [NSMutableArray array];
    }
    return self;
}

- (NSInteger)count
{
    return self.bookings.count;
}

- (SBBooking *)bookingAtIndex:(NSInteger)index
{
    return (SBBooking *)self.bookings[index]; // as far as SBBooking and LSBooking have same properties
}

@end