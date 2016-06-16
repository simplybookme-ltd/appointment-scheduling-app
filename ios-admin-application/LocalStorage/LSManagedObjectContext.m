//
//  LSManagedObjectContext.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "LSManagedObjectContext.h"

#define kLSSimplyBookObjectModelName @"SimplyBookDataModel"
#define kLSSimplyBookStorageFileName @"SimplyBook.sqlite"
#define kLSSimplyBookStorageURL ([[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:kLSSimplyBookStorageFileName])

@implementation LSManagedObjectContext

+ (NSManagedObjectModel *)simplyBookObjectModel
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kLSSimplyBookObjectModelName withExtension:@"momd"];
    if (modelURL) {
        return [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return nil;
}

+ (NSPersistentStoreCoordinator *)sb_defaultPersistentStoreCoordinator
{
    static dispatch_once_t onceToken;
    static NSPersistentStoreCoordinator *sb_defaultPersistentStoreCoordinator = nil;
    dispatch_once(&onceToken, ^{
        NSManagedObjectModel *model = [self simplyBookObjectModel];
        NSAssert(model != nil, @"can't create model object");
        sb_defaultPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES};
        NSError *error = nil;
        NSURL *storageURL = kLSSimplyBookStorageURL;
        NSAssert(storageURL != nil, @"storage URL can't be nil");
        if (![sb_defaultPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storageURL options:options error:&error]) {
            NSAssert(NO, @"impossible to add SQL type persistent store with URL: %@; error: %@", storageURL, error);
            sb_defaultPersistentStoreCoordinator = nil;
        }
    });
    return sb_defaultPersistentStoreCoordinator;
}

- (instancetype)init
{
    self = [super initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    if (self) {
        NSPersistentStoreCoordinator *coordinator = [[self class] sb_defaultPersistentStoreCoordinator];
        NSAssert(coordinator != nil, @"store coordinator can't be nil");
        if (coordinator != nil) {
            self.persistentStoreCoordinator = coordinator;
        }
    }
    return self;
}

- (instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    NSParameterAssert(coordinator != nil);
    self = [super initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    if (self) {
        self.persistentStoreCoordinator = coordinator;
    }
    return self;
}

- (NSArray <__kindof NSManagedObject *> *)fetchObjectOfEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSParameterAssert(entityName != nil);
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    [fetchRequest setEntity:entity];
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    NSArray *fetchedObjects = [self executeFetchRequest:fetchRequest error:error];
    if (fetchedObjects == nil) {
        return nil;
    }
    return fetchedObjects;
}

@end
