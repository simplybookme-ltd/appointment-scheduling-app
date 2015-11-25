//
//  SBPerformersCollection.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 20.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SBCollectionSortingProtocol <NSObject>

@property (nonatomic, strong, nullable, readonly) id primarySortingField;
@property (nonatomic, strong, nullable, readonly) id secondarySortingField;

@end

@protocol SBCollectionEntryProtocol <NSObject>

@property (nonatomic, strong, readonly) NSString *id;
@property (nonatomic, strong, readonly) NSString *name;

@end

@protocol SBCollectionEntryBuilderProtocol <NSObject>

- (nullable NSObject <SBCollectionEntryProtocol, SBCollectionSortingProtocol> *)entry;
- (nullable NSObject <SBCollectionEntryProtocol, SBCollectionSortingProtocol> *)entryWithDict:(NSDictionary <NSString *, id> *)dict;

@end

typedef NSObject <SBCollectionEntryProtocol, SBCollectionSortingProtocol> SBCollectionEntry;


@interface SBCollection <__covariant ObjectType : SBCollectionEntry *> : NSObject <NSFastEnumeration>

- (nullable instancetype)initWithDictionary:(NSDictionary <NSString *, id> *)dictionary builder:(NSObject <SBCollectionEntryBuilderProtocol> *)builder;
- (nullable instancetype)initWithArray:(NSArray <NSDictionary <NSString *, id> *> *)array builder:(NSObject <SBCollectionEntryBuilderProtocol> *)builder;

- (instancetype)collectionWithObjectsPassingTest:(BOOL (^)(ObjectType object, NSUInteger idx, BOOL *stop))test;

- (NSUInteger)indexForObject:(ObjectType)object;
- (ObjectType)objectAtIndexedSubscript:(NSUInteger)idx;
- (nullable ObjectType)objectForKeyedSubscript:(NSString *)objectID;
- (NSUInteger)count;

- (void)enumerateUsingBlock:(void (^)(NSString * objectID, ObjectType performer, BOOL * stop))block;
- (void)enumerateWithOptions:(NSEnumerationOptions)options usingBlock:(void (^)(NSString *objectID, ObjectType object, BOOL *stop))block;
- (NSArray <ObjectType> *)allObjects;
- (NSArray <ObjectType> *)objectsAtIndexes:(NSIndexSet *)indexes;
- (NSArray <ObjectType> *)objectsPassingTest:(BOOL (^)(ObjectType object, NSUInteger idx, BOOL *stop))test;

@end

NS_ASSUME_NONNULL_END