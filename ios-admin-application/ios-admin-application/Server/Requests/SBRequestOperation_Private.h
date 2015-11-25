//
//  SBRequest_Private.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 06.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBResultProcessor.h"
#import "SBRequestOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBRequestOperation (Private)

@property (nonatomic, readwrite) NSDictionary *headers;
@property (nonatomic, readwrite) NSString *endPointString;
@property (nonatomic, readonly) SBResultProcessor *resultProcessor;

- (nullable instancetype)initWithToken:(nullable NSString *)token comanyLogin:(nullable NSString *)companyLogin;
- (void)initializeWithToken:(nullable NSString *)token comanyLogin:(nullable NSString *)companyLogin endpoint:(NSString *)endpoint;
- (NSString *)method;
- (NSArray *)params;

@end

@interface SBResultProcessor (Private)

- (BOOL)chainResult:(id)result success:(BOOL)success;

@end

NS_ASSUME_NONNULL_END
