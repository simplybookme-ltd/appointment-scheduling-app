//
//  SBResponse.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBResultProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBResponse <ObjectType> : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *requestGUID;
@property (nonatomic, strong, nullable) ObjectType result;
@property (nonatomic, readonly, strong, nullable) NSError *error;
@property (nonatomic, getter=isCanceled) BOOL canceled;

+ (nullable instancetype)responseWithData:(nullable NSData *)data requestGUID:(nullable NSString *)GUID resultProcessor:(__kindof SBResultProcessor *)resultProcessor;

- (BOOL)isEqual:(SBResponse *)object;

@end

@interface SBErrorResponse : SBResponse

+ (instancetype)responseWithError:(NSError *)error requestGUID:(nullable NSString *)GUID;

@end

@interface SBNullResponse : SBResponse

+ (instancetype)nullResponse;

@end

@interface SBBooleanResponse : SBResponse

+ (instancetype)booleanResponseWithValue:(BOOL)value requestGUID:(nullable NSString *)GUID;

@end

@interface SBCachedResponse <ObjectType>: SBResponse

+ (instancetype)cachedResponseWithResult:(ObjectType)result requestGUID:(nullable NSString *)GUID;

@end

NS_ASSUME_NONNULL_END