//
//  LSBooking+CoreDataProperties.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LSBooking.h"

NS_ASSUME_NONNULL_BEGIN

@interface LSBooking (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *bookingID;
@property (nullable, nonatomic, retain) NSString *clientEmail;
@property (nullable, nonatomic, retain) NSString *clientID;
@property (nullable, nonatomic, retain) NSString *clientName;
@property (nullable, nonatomic, retain) NSString *clientPhone;
@property (nullable, nonatomic, retain) NSDate *endDate;
@property (nullable, nonatomic, retain) NSString *eventTitle;
@property (nullable, nonatomic, retain) NSNumber *isConfirmed;
@property (nullable, nonatomic, retain) NSString *paymentStatus;
@property (nullable, nonatomic, retain) NSString *paymentSystem;
@property (nullable, nonatomic, retain) NSString *performerID;
@property (nullable, nonatomic, retain) NSString *performerName;
@property (nullable, nonatomic, retain) NSDate *recordDate;
@property (nullable, nonatomic, retain) NSDate *startDate;
@property (nullable, nonatomic, retain) NSString *statusID;
@property (nullable, nonatomic, retain) NSNumber *searchID;
@property (nullable, nonatomic, retain) NSDate *lastUpdate;

@end

NS_ASSUME_NONNULL_END
