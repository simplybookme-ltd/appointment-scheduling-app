//
//  LSPerformer.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SBCollection.h"

NS_ASSUME_NONNULL_BEGIN

@interface LSPerformer : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

@interface LSPerformer (SBCollection) <SBCollectionEntryProtocol, SBCollectionSortingProtocol>

@property (nonatomic, strong, readonly) NSString *id;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, nullable, readonly) id primarySortingField;
@property (nonatomic, strong, nullable, readonly) id secondarySortingField;

@end

NS_ASSUME_NONNULL_END

#import "LSPerformer+CoreDataProperties.h"
