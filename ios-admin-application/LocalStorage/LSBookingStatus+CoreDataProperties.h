//
//  LSBookingStatus+CoreDataProperties.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LSBookingStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface LSBookingStatus (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *statusID;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *isDefault;
@property (nullable, nonatomic, retain) NSString *hexColor;
@property (nullable, nonatomic, retain) NSNumber *searchID;
@property (nullable, nonatomic, retain) NSDate *lastUpdate;

@end

NS_ASSUME_NONNULL_END
