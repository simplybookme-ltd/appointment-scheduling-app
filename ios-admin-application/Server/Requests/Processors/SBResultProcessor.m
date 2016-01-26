//
//  SBResultProcessor.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 21.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBResultProcessor.h"
#import "SBRequestOperation.h"

@interface SBResultProcessor ()
{
    SBResultProcessor *nextProcessor;
}
@end

@implementation SBResultProcessor

- (BOOL)process:(id)result
{
    return [self chainResult:result success:YES];
}

- (SBResultProcessor *)addResultProcessorToChain:(SBResultProcessor *)processor
{
    NSParameterAssert(processor != nil);
    nextProcessor = processor;
    return self;
}

- (BOOL)chainResult:(id)result success:(BOOL)success
{
    if (!success) {
        return NO;
    } else if (nextProcessor) {
        success = [nextProcessor process:result];
        self.result = nextProcessor.result;
        self.error = nextProcessor.error;
        return success;
    }
    self.result = result;
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ -> %@", NSStringFromClass([self class]), (nextProcessor ? [nextProcessor description] : @"null")];
}

@end

#pragma mark -

@implementation SBClassCheckProcessor

+ (instancetype)classCheckProcessorWithExpectedClass:(Class)expectedClass
{
    NSParameterAssert(expectedClass != nil);
    return [[self alloc] initWithExpectedClass:expectedClass];
}

- (instancetype)initWithExpectedClass:(Class)expectedClass
{
    NSParameterAssert(expectedClass != nil);
    self = [super init];
    if (self) {
        self.expectedClass = expectedClass;
    }
    return self;
}

- (BOOL)process:(id)result
{
    self.result = result;
    
    /**
     * empty dictionary in PHP can be encoded to JSON as empty array
     */
    if (self.expectedClass == [NSDictionary class] && [result isKindOfClass:[NSArray class]]) {
        if ([result count] == 0) {
            return [self chainResult:@{} success:YES];
        }
    }
    if (![result isKindOfClass:self.expectedClass]) {
        NSString *localizedDescription = [NSString stringWithFormat:@"Unexpected result type. '%@' expected, '%@' occurred.", NSStringFromClass(self.expectedClass), NSStringFromClass([result class])];
        self.error = [NSError errorWithDomain:SBRequestErrorDomain code:SBUnknownErrorCode userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
        return NO;
    }
    return [self chainResult:result success:YES];
}

@end

#pragma mark -

@implementation SBDebugProcessor

+ (instancetype)debugProcessor
{
    return [[self alloc] init];
}

- (BOOL)process:(id)result
{
    NSLog(@"(%@) %@", NSStringFromClass([result class]), result);
    self.result = result;
    return [self chainResult:result success:YES];
}

@end

#pragma mark -

@implementation SBSafeDictionaryProcessor

+ (instancetype)safeDictionaryProcessor
{
    return [[self alloc] initWithExpectedClass:[NSDictionary class]];
}

+ (instancetype)classCheckProcessorWithExpectedClass:(Class)expectedClass
{
    return [self safeDictionaryProcessor];
}

- (Class)expectedClass
{
    return [NSDictionary class];
}

- (NSDictionary *)safeDict:(NSDictionary *)dict
{
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            res[key] = [self safeDict:obj];
        }
        else if (![obj isEqual:[NSNull null]]) {
            res[key] = obj;
        }
    }];
    return res;
}

- (BOOL)process:(id)result
{
    if (![super process:result]) {
        return [self chainResult:result success:NO];
    }
    self.result = [self safeDict:(NSDictionary *)result];
    return [self chainResult:self.result success:YES];
}

@end

#pragma mark -

@implementation SBNumberProcessor

- (BOOL)process:(id)result
{
    if ([result isKindOfClass:[NSNumber class]]) {
        self.result = result;
        return [self chainResult:result success:YES];
    }
    else if ([result isKindOfClass:[NSString class]]) {
        NSScanner *scanner = [NSScanner scannerWithString:result];
        double d = 0;
        if ([[result lowercaseString] rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].location == NSNotFound && [scanner scanDouble:&d]) {
            self.result = [NSNumber numberWithDouble:d];
            return [self chainResult:self.result success:YES];
        }
        else {
            self.result = result;
            NSString *localizedDescription = [NSString stringWithFormat:@"Unexpected result type. NSNumber or NSString with numeric value expected. Nonnumeric string occurred."];
            self.error = [NSError errorWithDomain:SBRequestErrorDomain code:SBUnknownErrorCode userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
            return [self chainResult:self.result success:NO];
        }
    }
    self.result = result;
    NSString *localizedDescription = [NSString stringWithFormat:@"Unexpected result type. NSNumber or NSString with numeric value expected, '%@' occurred.", NSStringFromClass([result class])];
    self.error = [NSError errorWithDomain:SBRequestErrorDomain code:SBUnknownErrorCode userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
    return [self chainResult:result success:NO];
}

@end