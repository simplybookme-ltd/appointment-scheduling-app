//
//  SBCache.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 27.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBCache.h"
#import "SBRequestOperation_Private.h"

NSString * const kSBCache_WillInvalidateCacheForRequestNotification = @"kSBCache_WillInvalidateCacheForRequestNotification";
NSString * const kSBCache_DidInvalidateCacheForRequestNotification = @"kSBCache_DidInvalidateCacheForRequestNotification";
NSString * const kSBCache_WillInvalidateCacheNotification = @"kSBCache_WillInvalidateCacheNotification";
NSString * const kSBCache_DidInvalidateCacheNotification = @"kSBCache_DidInvalidateCacheNotification";
NSString * const kSBCache_RequestObjectUserInfoKey = @"kSBCache_RequestObjectUserInfoKey";
NSString * const kSBCache_RequestClassUserInfoKey = @"kSBCache_RequestClassUserInfoKey";

@protocol SBCacheProvider <NSObject>

- (void)cacheResponse:(SBResponse *)response forRequest:(SBRequestOperation *)request;
- (SBResponse *)responseForRequest:(SBRequestOperation *)request;
- (void)invalidateCacheForRequest:(SBRequestOperation *)request;
- (void)invalidateCacheForRequestClass:(Class)requestClass;
- (void)flush;

@end

typedef NSObject <SBCacheProvider> SBCacheProvider;

@interface SBMemoryCacheProvider : NSObject <SBCacheProvider>
{
    NSCache *storage;
    NSMutableDictionary <id, NSString *> *classes;
}
@end

@interface SBNullCacheProvider : NSObject <SBCacheProvider>
@end

@interface SBCache ()
{
    NSMutableDictionary <id, SBCacheProvider *> *cacheProviders;
}

+ (id)cacheProviderForPolicy:(SBCachePolicy)policy;

@end

@implementation SBCache

+ (id)cacheProviderForPolicy:(SBCachePolicy)policy
{
    switch (policy) {
        case SBNoCachePolicy:
        case SBIgnoreCachePolicy:
            return [SBNullCacheProvider new];
        case SBMemoryCachePolicy:
            return [SBMemoryCacheProvider new];
            
        default:
            NSAssert(NO, @"unexpected cache policy %ld", (long)policy);
            break;
    }
    return nil;
}

+ (instancetype)cache
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        cacheProviders = [NSMutableDictionary dictionary];
    }
    return self;
}

- (SBCacheProvider *)cacheProviderForPolicy:(SBCachePolicy)policy
{
    SBCacheProvider *provider = [cacheProviders objectForKey:@(policy)];
    if (!provider) {
        if (policy == SBNoCachePolicy || policy == SBIgnoreCachePolicy) {
            provider = [SBNullCacheProvider new];
        }
        else if (policy == SBMemoryCachePolicy) {
            provider = [SBMemoryCacheProvider new];
        }
        [cacheProviders setObject:provider forKey:@(policy)];
    }
    return provider;
}

- (void)cacheResponse:(SBResponse *)response forRequest:(SBRequestOperation *)request
{
    NSParameterAssert(response != nil);
    NSParameterAssert(request != nil);
    if (response.error || response.canceled || [response isEqual:[SBNullResponse nullResponse]]) {
        return;
    }
    SBCacheProvider *provider = [self cacheProviderForPolicy:request.cachePolicy];
    [provider cacheResponse:response forRequest:request];
}

- (SBResponse *)responseForRequest:(SBRequestOperation *)request
{
    SBCacheProvider *provider = [self cacheProviderForPolicy:request.cachePolicy];
    return [provider responseForRequest:request];
}

- (void)invalidateCacheForRequest:(SBRequestOperation *)request
{
    SBCacheProvider *provider = [self cacheProviderForPolicy:request.cachePolicy];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSBCache_WillInvalidateCacheForRequestNotification object:self
                                                      userInfo:@{kSBCache_RequestObjectUserInfoKey: request}];
    [provider invalidateCacheForRequest:request];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSBCache_DidInvalidateCacheForRequestNotification object:self
                                                      userInfo:@{kSBCache_RequestObjectUserInfoKey: request}];
}

- (void)invalidateCacheForRequestClass:(Class)requestClass
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kSBCache_WillInvalidateCacheForRequestNotification object:self
                                                      userInfo:@{kSBCache_RequestClassUserInfoKey: requestClass}];
    [cacheProviders enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, SBCacheProvider * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj invalidateCacheForRequestClass:requestClass];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSBCache_DidInvalidateCacheForRequestNotification object:self
                                                      userInfo:@{kSBCache_RequestClassUserInfoKey: requestClass}];
}

- (void)flush
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kSBCache_WillInvalidateCacheNotification object:self];
    [cacheProviders enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, SBCacheProvider * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj flush];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSBCache_DidInvalidateCacheNotification object:self];
}

@end

#pragma mark -

@implementation SBMemoryCacheProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        storage = [[NSCache alloc] init];
        classes = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)cacheResponse:(SBResponse *)response forRequest:(SBRequestOperation *)request
{
    NSParameterAssert(response.result != nil);
    if (!response || !response.result || !request || ![request cacheKey]) {
        return;
    }
    [storage setObject:response.result forKey:[request cacheKey]];
    classes[[request cacheKey]] = NSStringFromClass([request class]);
}

- (SBResponse *)responseForRequest:(SBRequestOperation *)request
{
    NSParameterAssert(request != nil);
    id resultObject = [storage objectForKey:[request cacheKey]];
    if (resultObject) {
        return [SBCachedResponse cachedResponseWithResult:resultObject requestGUID:request.GUID];
    }
    return nil;
}

- (void)invalidateCacheForRequest:(SBRequestOperation *)request
{
    NSParameterAssert(request != nil);
    [storage removeObjectForKey:[request cacheKey]];
    [classes removeObjectForKey:[request cacheKey]];
}

- (void)invalidateCacheForRequestClass:(Class)requestClass
{
    NSString *classString = NSStringFromClass(requestClass);
    NSSet *candidates = [classes keysOfEntriesPassingTest:^BOOL(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        return [obj isEqualToString:classString];
    }];
    [candidates enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        [storage removeObjectForKey:obj];
        [classes removeObjectForKey:obj];
    }];
}

- (void)flush
{
    [storage removeAllObjects];
}

@end

#pragma mark -

@implementation SBNullCacheProvider

- (void)cacheResponse:(SBResponse *)response forRequest:(SBRequestOperation *)request
{
    // no caching
}

- (SBResponse *)responseForRequest:(SBRequestOperation *)request
{
    return nil;
}

- (void)invalidateCacheForRequest:(NSObject<SBRequestProtocol> *)request
{
    // nothing to do
}

- (void)invalidateCacheForRequestClass:(Class)requestClass
{
    // nothing to do
}

- (void)flush
{
    // nothing to do
}

@end