//
//  SBPerformer.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBCollection.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBPerformer : SBCollectionEntry

@property (nonatomic, strong) NSString *performerID;
@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, strong, nullable) NSString *performerDescription;
@property (nonatomic, strong, nullable) NSString *email;
@property (nonatomic, strong, nullable) NSString *phone;
@property (nonatomic, strong, nullable) NSString *picture;
@property (nonatomic, strong) NSString *picturePath;
@property (nonatomic, strong) NSNumber *position;
@property (nonatomic, strong, nullable) NSString *color;
@property (nonatomic, strong, nullable) NSNumber *isActive;
@property (nonatomic, strong, nullable) NSNumber *isVisible;

@end

@interface SBPerformerEntryBuilder : NSObject <SBCollectionEntryBuilderProtocol>

@end

typedef SBCollection <SBPerformer *> SBPerformersCollection;

NS_ASSUME_NONNULL_END