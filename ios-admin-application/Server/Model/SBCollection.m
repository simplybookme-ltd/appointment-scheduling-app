//
//  SBPerformersCollection.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 20.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBCollection.h"

@interface SBCollection ()

@property (nonatomic, strong) NSObject <SBCollectionEntryBuilderProtocol> *builder;
@property (nonatomic, strong) NSArray <NSString *> *sortedKeys;
@property (nonatomic, strong) NSMutableDictionary <NSString *, SBCollectionEntry *> *objects;

@end

@implementation SBCollection

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.objects = [NSMutableDictionary dictionary];
        self.sortedKeys = [self sortedKeysForObjects:self.objects];
    }
    return self;
}

- (nullable instancetype)initWithDictionary:(NSDictionary <NSString *, id> *)dictionary builder:(NSObject <SBCollectionEntryBuilderProtocol> *)builder
{
    return [self initWithArray:[dictionary allValues] builder:builder];
}

- (nullable instancetype)initWithArray:(NSArray <NSDictionary <NSString *, id> *> *)array builder:(NSObject <SBCollectionEntryBuilderProtocol> *)builder
{
    self = [super init];
    if (self) {
        self.builder = builder;
        self.objects = [NSMutableDictionary dictionary];
        [array enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SBCollectionEntry *entry = [builder entryWithDict:obj];
            self.objects[entry.id] = entry;
        }];
        self.sortedKeys = [self sortedKeysForObjects:self.objects];
    }
    return self;
}

- (nullable instancetype)initWithObjects:(NSArray <SBCollectionEntry *> *)objects builder:(NSObject <SBCollectionEntryBuilderProtocol> *)builder
{
    self = [super init];
    if (self) {
        self.builder = builder;
        self.objects = [NSMutableDictionary dictionary];
        [objects enumerateObjectsUsingBlock:^(SBCollectionEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
            self.objects[entry.id] = entry;
        }];
        self.sortedKeys = [self sortedKeysForObjects:self.objects];
    }
    return self;
}

- (instancetype)collectionWithObjectsPassingTest:(BOOL (^)(SBCollectionEntry *object, NSUInteger idx, BOOL *stop))test
{
    return [[[self class] alloc] initWithObjects:[self objectsPassingTest:test] builder:self.builder];
}

- (NSArray <NSString *> *)sortedKeysForObjects:(NSDictionary <NSString *, SBCollectionEntry *> *)objects
{
    return [objects keysSortedByValueWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSObject<SBCollectionSortingProtocol> * obj1, NSObject<SBCollectionSortingProtocol> * obj2) {
        NSComparisonResult comparisonResult = [obj1.primarySortingField compare:obj2.primarySortingField];
        return comparisonResult == NSOrderedSame ? [obj1.secondarySortingField compare:obj2.secondarySortingField] : comparisonResult;
    }];
}

- (NSUInteger)indexForObject:(NSObject<SBCollectionEntryProtocol> *)object
{
    NSParameterAssert(object != nil);
    NSAssert(object.id != nil && ![object.id isEqualToString:@""], @"invalid collection entry object");
    return [self.sortedKeys indexOfObject:object.id];
}

- (NSUInteger)count
{
    return self.objects.count;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@ %p:{\n", NSStringFromClass([self class]), self];
    for (NSString *performerID in self.sortedKeys) {
        [description appendFormat:@"\t%@\n", [self.objects[performerID] description]];
    }
    [description appendString:@">"];
    return description;
}

#pragma mark - Object Subscripting

- (SBCollectionEntry *)objectAtIndexedSubscript:(NSUInteger)idx
{
    NSParameterAssert(idx < self.sortedKeys.count);
    return self.objects[self.sortedKeys[idx]];
}

- (nullable SBCollectionEntry *)objectForKeyedSubscript:(NSString *)performerID
{
    NSParameterAssert(performerID != nil);
    return self.objects[performerID];
}

#pragma mark - Fast enumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained[])buffer count:(NSUInteger)len
{
    return [[self.objects allValues] countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Enumeration

- (void)enumerateUsingBlock:(void (^)(NSString *objectID, SBCollectionEntry *object, BOOL *stop))block
{
    NSParameterAssert(block != NULL);
    [self.objects enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        block(key, obj, stop);
    }];
}

- (void)enumerateWithOptions:(NSEnumerationOptions)options usingBlock:(void (^)(NSString *objectID, SBCollectionEntry *object, BOOL *stop))block
{
    NSParameterAssert(block != NULL);
    [self.objects enumerateKeysAndObjectsWithOptions:options usingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        block(key, obj, stop);
    }];
}

#pragma mark - Accessing performers

- (NSArray<SBCollectionEntry *> *)allObjects
{
    NSAssert(self.builder != nil, @"collection not configured");
    return [self.objects objectsForKeys:self.sortedKeys notFoundMarker:[self.builder entry]]; // sorted array
}

- (NSArray<SBCollectionEntry *> *)objectsAtIndexes:(NSIndexSet *)indexes
{
    NSParameterAssert(indexes != nil);
    NSAssert(self.builder != nil, @"collection not configured");
    return [self.objects objectsForKeys:[self.sortedKeys objectsAtIndexes:indexes] notFoundMarker:[self.builder entry]];
}

- (NSArray <SBCollectionEntry *> *)objectsPassingTest:(BOOL (^)(SBCollectionEntry *object, NSUInteger idx, BOOL *stop))test
{
    NSParameterAssert(test != NULL);
    NSIndexSet *indexes = [self.sortedKeys indexesOfObjectsPassingTest:^BOOL(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return test(self.objects[obj], idx, stop);
    }];
    return [self objectsAtIndexes:indexes];
}

@end

@implementation SBMutableCollection

- (void)addObject:(SBCollectionEntry *)object
{
    [self.objects setObject:object forKey:object.id];
    self.sortedKeys = [self sortedKeysForObjects:self.objects];
}

- (void)removeAll
{
    [self.objects removeAllObjects];
    self.sortedKeys = [self sortedKeysForObjects:self.objects];
}

@end

