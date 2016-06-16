//
//  SBCache.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 27.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBResponse.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSBCache_WillInvalidateCacheForRequestNotification;
extern NSString * const kSBCache_DidInvalidateCacheForRequestNotification;
extern NSString * const kSBCache_WillInvalidateCacheNotification;
extern NSString * const kSBCache_DidInvalidateCacheNotification;
extern NSString * const kSBCache_RequestObjectUserInfoKey;
extern NSString * const kSBCache_RequestClassUserInfoKey;

typedef NS_ENUM(NSInteger, SBCachePolicy)
{
    SBNoCachePolicy,
    SBMemoryCachePolicy,
    SBIgnoreCachePolicy
};

@protocol SBRequestProtocol;

@interface SBCache : NSObject

+ (nullable instancetype)cache;

- (void)cacheResponse:(SBResponse *)response forRequest:(nonnull NSObject<SBRequestProtocol> *)request;
- (nullable SBResponse *)responseForRequest:(nonnull NSObject<SBRequestProtocol> *)request;
- (void)invalidateCacheForRequest:(nonnull NSObject<SBRequestProtocol> *)request;
- (void)invalidateCacheForRequestClass:(Class)requestClass;
- (void)flush;

@end

NS_ASSUME_NONNULL_END