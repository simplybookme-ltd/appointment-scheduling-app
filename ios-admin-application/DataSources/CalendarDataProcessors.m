//
//  CalendarDataProcessors.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 31.10.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "CalendarDataProcessors.h"
#import "LSManagedObjectContext.h"
#import "LSBooking.h"
#import "LSPerformer.h"

@interface CalendarDataPerformersLocalSaverDataProcessor ()

@property (nonatomic, strong) LSManagedObjectContext *managedObjectContext;

@end

@implementation CalendarDataPerformersLocalSaverDataProcessor

- (LSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = [[LSManagedObjectContext alloc] init];
    }
    return _managedObjectContext;
}

- (void)process:(CalendarDataLoaderResult *)result
{
    NSParameterAssert(result != nil);
    if (result.performers == nil || result.performers.count == 0) {
        return;
    }
    for (SBPerformer *performer in result.performers) {
        NSError *error = nil;
        LSPerformer *stored = [[self.managedObjectContext fetchObjectOfEntity:NSStringFromClass([LSPerformer class])
                                                                withPredicate:[NSPredicate predicateWithFormat:@"searchID = %@", @([performer.performerID integerValue])]
                                                                        error:&error] firstObject];
        if (error) {
            return ;
        }
        if (!stored) {
            stored = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([LSPerformer class])
                                                   inManagedObjectContext:self.managedObjectContext];
            stored.performerID = performer.performerID;
            stored.searchID = @(performer.performerID.integerValue);
        } else {
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
    }
    NSError *error = nil;
    [self.managedObjectContext save:&error];
}

@end

#pragma mark -

@interface CalendarDataBookingsDataLocalSaverProcessor ()

@property (nonatomic, strong) LSManagedObjectContext *managedObjectContext;

@end

@implementation CalendarDataBookingsDataLocalSaverProcessor

- (LSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = [[LSManagedObjectContext alloc] init];
    }
    return _managedObjectContext;
}

- (void)process:(CalendarDataLoaderResult *)result
{
    NSParameterAssert(result != nil);
    if (result.bookings == nil || result.bookings.count == 0) {
        return;
    }
    NSError *error = nil;
    for (SBBooking *booking in result.bookings) {
        LSBooking *stored = [[self.managedObjectContext fetchObjectOfEntity:NSStringFromClass([LSBooking class])
                                                              withPredicate:[NSPredicate predicateWithFormat:@"searchID = %@", @([booking.bookingID integerValue])]
                                                                      error:&error] firstObject];
        if (error) {
            continue;
        }
        if (!stored) {
            stored = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([LSBooking class])
                                                   inManagedObjectContext:self.managedObjectContext];
            stored.bookingID = booking.bookingID;
            stored.searchID = @(booking.bookingID.integerValue);
        }
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
    [self.managedObjectContext save:&error];
}

@end
