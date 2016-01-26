//
//  SBResponse.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBResponse.h"
#import "SBRequestOperation.h"

@interface SBResponse <ObjectType> ()

@property (nonatomic, copy, readwrite) NSString *requestGUID;
@property (nonatomic, strong, readwrite) NSError *error;

- (instancetype)initWithResultObject:(ObjectType)resultObject requestGUID:(NSString *)GUID;

@end

@interface SBErrorResponse ()

- (instancetype)initWithError:(NSError *)error requestGUID:(NSString *)GUID;
- (instancetype)initWithError:(NSError *)error result:(NSDictionary *)data requestGUID:(NSString *)GUID;
- (instancetype)initWithErrorDomain:(NSString *)errorDomain code:(NSInteger)errorCode message:(NSString *)errorMessage result:(NSDictionary *)data requestGUID:(NSString *)GUID;

@end

@interface SBNullResponse ()

+ (instancetype)nullResponseWithRequestGUID:(NSString *)GUID;

@end

@implementation SBResponse

+ (instancetype)responseWithData:(NSData *)data requestGUID:(NSString *)GUID resultProcessor:(SBResultProcessor *)resultProcessor
{
    NSParameterAssert(resultProcessor != nil);
    if (!data) {
        return [[SBErrorResponse alloc] initWithErrorDomain:SBRequestErrorDomain
                                                       code:SBEmptyResponseBodyErrorCode
                                                    message:@"Server response with zero length message."
                                                     result:nil requestGUID:GUID];
    }
    NSError *error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data
                                                           options:NSJSONReadingMutableContainers
                                                             error:&error];
    if (error) {
        return [[SBErrorResponse alloc] initWithError:error requestGUID:GUID];
    }
    if (result[@"error"]) {
        if ([[result[@"error"][@"message"] lowercaseString] isEqualToString:@"access denied"]) {
            return [[SBErrorResponse alloc] initWithErrorDomain:SBRequestErrorDomain
                                                           code:SBInvalidAuthTokenErrorCode
                                                        message:@"Invalid auth token."
                                                         result:result
                                                    requestGUID:GUID];
        } else {
            return [[SBErrorResponse alloc] initWithErrorDomain:SBServerErrorDomain
                                                           code:[result[@"error"][@"code"] integerValue]
                                                        message:@"Server response with error."
                                                         result:result
                                                    requestGUID:GUID];
        }
    }
    if (!result[@"result"]
        || ([result isKindOfClass:[NSString class]] && [result[@"result"] isEqualToString:@""])
        || [result[@"result"] isEqual:[NSNull null]])
    {
        return [SBNullResponse nullResponseWithRequestGUID:GUID];
    }
    if (![resultProcessor process:result[@"result"]]) {
        return [[SBErrorResponse alloc] initWithError:resultProcessor.error result:result requestGUID:GUID];
    } else {
        return [[self alloc] initWithResultObject:resultProcessor.result requestGUID:GUID];
    }
}

- (instancetype)initWithResultObject:(id)resultObject requestGUID:(NSString *)GUID
{
    self = [super init];
    if (self) {
        self.requestGUID = GUID;
        self.result = resultObject;
    }
    return self;
}

- (BOOL)isEqual:(SBResponse *)object
{
    NSParameterAssert(object != nil);
    return [self.result isEqual:object.result];
}

- (NSString *)description
{
    return [@{@"GUID" : self.requestGUID,
              @"result" : (self.result ? self.result : [NSNull null]),
              @"error" : (self.error ? self.error : [NSNull null])} description];
}

@end

#pragma mark -

@implementation SBErrorResponse

+ (instancetype)responseWithError:(NSError *)error requestGUID:(NSString *)GUID
{
    NSParameterAssert(error != nil);
    return [[self alloc] initWithError:error requestGUID:GUID];
}

- (instancetype)initWithError:(NSError *)error requestGUID:(NSString *)GUID
{
    NSParameterAssert(error != nil);
    self = [super init];
    if (self) {
        self.error = error;
        self.requestGUID = GUID;
    }
    return self;
}

- (instancetype)initWithError:(NSError *)error result:(NSDictionary *)data requestGUID:(NSString *)GUID
{
    NSParameterAssert(error != nil);
    self = [super init];
    if (self) {
        self.error = error;
        self.requestGUID = GUID;
        self.result = data;
    }
    return self;
}

- (instancetype)initWithErrorDomain:(NSString *)errorDomain code:(NSInteger)errorCode message:(nullable NSString *)errorMessage result:(NSDictionary *)data requestGUID:(NSString *)GUID
{
    NSParameterAssert(errorDomain != nil);
    self = [super init];
    if (self) {
        self.result = data;
        self.requestGUID = GUID;
        if (errorMessage) {
            self.error = [NSError errorWithDomain:errorDomain
                                             code:errorCode
                                         userInfo:@{NSLocalizedDescriptionKey: errorMessage,
                                                    SBServerMessageKey: data[@"error"][@"message"]}];
        } else {
            self.error = [NSError errorWithDomain:errorDomain
                                             code:errorCode
                                         userInfo:@{NSLocalizedDescriptionKey: data[@"error"][@"message"]}];
        }
    }
    return self;
}

@end

#pragma mark -

@implementation SBNullResponse

+ (instancetype)nullResponse
{
    return [[self alloc] initWithResultObject:[NSNull null] requestGUID:nil];
}

+ (instancetype)nullResponseWithRequestGUID:(NSString *)GUID
{
    return [[self alloc] initWithResultObject:[NSNull null] requestGUID:GUID];
}

@end

#pragma mark -

@implementation SBBooleanResponse

+ (instancetype)booleanResponseWithValue:(BOOL)value requestGUID:(NSString *)GUID
{
    return [[self alloc] initWithResultObject:@(value) requestGUID:GUID];
}

@end

#pragma mark -

@implementation SBCachedResponse

+ (instancetype)cachedResponseWithResult:(id)result requestGUID:(NSString *)GUID
{
    NSParameterAssert(result != nil);
    return [[self alloc] initWithResultObject:result requestGUID:GUID];
}

@end