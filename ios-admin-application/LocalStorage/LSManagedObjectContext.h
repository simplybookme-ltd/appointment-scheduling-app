//
//  LSManagedObjectContext.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

@import UIKit;
@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@interface LSManagedObjectContext : NSManagedObjectContext

+ (nullable NSManagedObjectModel *)simplyBookObjectModel;

- (instancetype)init;
- (instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

- (NSArray <__kindof NSManagedObject *> *)fetchObjectOfEntity:(NSString *)entityName withPredicate:(nullable NSPredicate *)predicate error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END