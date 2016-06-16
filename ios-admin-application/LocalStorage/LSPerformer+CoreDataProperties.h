//
//  LSPerformer+CoreDataProperties.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LSPerformer.h"

NS_ASSUME_NONNULL_BEGIN

@interface LSPerformer (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *performerID;
@property (nullable, nonatomic, retain) NSNumber *searchID;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *performerDescription;
@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSString *phone;
@property (nullable, nonatomic, retain) NSString *picture;
@property (nullable, nonatomic, retain) NSString *picturePath;
@property (nullable, nonatomic, retain) NSNumber *position;
@property (nullable, nonatomic, retain) NSString *color;
@property (nullable, nonatomic, retain) NSNumber *isActive;
@property (nullable, nonatomic, retain) NSNumber *isVisible;
@property (nullable, nonatomic, retain) NSDate *lastUpdate;

@end

NS_ASSUME_NONNULL_END
