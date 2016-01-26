//
//  SBService.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBCollection.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBService : SBCollectionEntry

@property (nonatomic, strong) NSString *serviceID;
@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, strong, nullable) NSString *serviceDescription;
@property (nonatomic, strong, nullable) NSString *picture;
@property (nonatomic, strong) NSString *picturePath;
@property (nonatomic, strong) NSNumber *position;
@property (nonatomic, strong, nullable) NSNumber *isActive;
@property (nonatomic, strong, nullable) NSNumber *isPublic;
@property (nonatomic, strong, nullable) NSNumber *isRecurring;
@property (nonatomic, strong) NSNumber *duration;
@property (nonatomic, strong) NSNumber *hideDuration;
@property (nonatomic, strong, nullable) NSDictionary <NSString *, NSNumber *> *unitMap;
@property (nonatomic, strong, nullable) NSNumber *price;
@property (nonatomic, strong, nullable) NSString *currency;

@end

@interface SBServiceEntryBuilder : NSObject <SBCollectionEntryBuilderProtocol>

@end

typedef SBCollection <SBService *> SBServicesCollection;

NS_ASSUME_NONNULL_END
