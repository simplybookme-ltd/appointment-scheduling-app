//
//  SBRequest.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 06.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBRequestOperation.h"
#import "SBRequestOperation_Private.h"

#define kSBRequestTimeout 20

NSString *const SBRequestErrorDomain = @"SBRequestErrorDomain";
NSString *const SBServerErrorDomain = @"SBServerErrorDomain";
NSString *const SBServerMessageKey = @"SBServerMessageKey";

static NSString *const kSBDefaultEndpoint = @"https://user-api.simplybook.me/admin";
static NSString *const kSBLoginEndpoint = @"https://user-api.simplybook.me/login";

@interface SBRequestOperation () <SBRequestDelegate>
{
    NSString *token;
    NSString *GUID;
    NSUInteger requestID;
    NSURLSessionTask *URLSessionTask;
}

@property (nonatomic, readwrite, copy) NSString *companyLogin;

@end

@implementation SBRequestOperation

@synthesize endPointString = _endPointString;
@synthesize requestID = requestID;
@synthesize GUID = GUID;
@synthesize delegate;
@synthesize callback;
@synthesize cachePolicy = _cachePolicy;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeWithToken:nil comanyLogin:nil endpoint:kSBDefaultEndpoint];
    }
    return self;
}

- (instancetype)initWithToken:(NSString *)_token comanyLogin:(NSString *)companyLogin
{
    self = [super init];
    if (self) {
        [self initializeWithToken:_token comanyLogin:companyLogin endpoint:kSBDefaultEndpoint];
    }
    return self;
}

- (instancetype)initWithToken:(NSString *)_token comanyLogin:(NSString *)companyLogin endpoint:(NSString *)endpoint
{
    NSParameterAssert(endpoint != nil);
    self = [super init];
    if (self) {
        [self initializeWithToken:_token comanyLogin:companyLogin endpoint:endpoint];
    }
    return self;
}

- (void)initializeWithToken:(NSString *)_token comanyLogin:(NSString *)companyLogin endpoint:(NSString *)endpoint
{
    NSParameterAssert(endpoint != nil);
    self.cachePolicy = SBMemoryCachePolicy;
    token = _token;
    self.companyLogin = companyLogin;
    requestID = arc4random();
    _endPointString = endpoint;
    GUID = [NSString stringWithFormat:@"%@-%@", NSStringFromClass([self class]), [[NSProcessInfo processInfo] globallyUniqueString]];
    self.delegate = self;
    __weak id weakSelf = self;
    [self addExecutionBlock:^{
        [weakSelf performRequest];
    }];
}

- (instancetype)copyWithToken:(NSString *)_token
{
    NSParameterAssert(_token != nil);
    typeof(self) copy = [[[self class] alloc] initWithToken:_token comanyLogin:self.companyLogin];
    copy.callback = self.callback;
    copy.delegate = self.delegate;
    copy.cachePolicy = self.cachePolicy;
    copy->GUID = self.GUID;
    return copy;
}

#pragma mark -

- (NSURL *)endPointURL
{
    return [NSURL URLWithString:_endPointString];
}

- (NSDictionary *)headers
{
    if (self.companyLogin != nil && token != nil) {
        return @{
                 @"Accept" : @"application/json",
                 @"Content-Type": @"application/json",
                 @"X-Company-Login" : self.companyLogin,
                 @"X-User-Token" : token
                 };
    } else {
        return @{
                 @"Accept" : @"application/json",
                 @"Content-Type": @"application/json"
                 };
    }
}

- (NSArray *)params
{
    return @[];
}

- (NSString *)method
{
    NSAssert(NO, @"this method should be overwriten by subclasses");
    return @"";
}

- (void)cancel
{
    [URLSessionTask cancel];
    [super cancel];
}

- (NSString *)description
{
    return [@{@"URL" : [self endPointString], @"headers" : [self headers], @"request" : [self requestParams], @"GUID" : self.GUID} description];
}

#pragma mark -

- (NSDictionary *)requestParams
{
    return @{
             @"jsonrpc" : @"2.0",
             @"id" : @([self requestID]),
             @"method": [self method],
             @"params": [self params]
             };
}

- (void)performRequest
{
    if ([self.delegate respondsToSelector:@selector(shouldDispatchRequest:)]) {
        if (![self.delegate shouldDispatchRequest:self]) {
            return;
        }
    }
    if (self.predispatchBlock) {
        self.predispatchBlock(self);
    }
    SBResponse *cachedResponse = [[SBCache cache] responseForRequest:self];
    if (cachedResponse) {
        if ([self.delegate request:self didFinishWithResponse:cachedResponse]) {
            self.callback(cachedResponse);
        }
        return;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self endPointURL]
                                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                            timeoutInterval:kSBRequestTimeout];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:[self headers]];
    
    NSError *error;
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:[self requestParams]
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:&error];
    if (error) {
        SBResponse *response = [SBErrorResponse responseWithError:error requestGUID:self.GUID];
        self.callback(response);
        return;
    }
    [request setHTTPBody:requestBody];
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.URLCache = nil;
    sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    URLSessionTask = [session dataTaskWithRequest:request
                                completionHandler:^(NSData *data, NSURLResponse *URLResponse, NSError *_error) {
                                    SBResponse *response = nil;
                                    if (_error) {
                                        response = [SBErrorResponse responseWithError:_error requestGUID:self.GUID];
                                        if (_error.code == NSURLErrorCancelled) {
                                            response.canceled = YES;
                                        }
                                    } else {
                                        response = [SBResponse responseWithData:data requestGUID:self.GUID resultProcessor:self.resultProcessor];
                                    }
                                    if ([self.delegate request:self didFinishWithResponse:response]) {
                                        [[SBCache cache] cacheResponse:response forRequest:self];
                                        self.callback(response);
                                    }
                                    dispatch_semaphore_signal(semaphore);
                                }];
    [URLSessionTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (NSData *)cacheKey
{
    NSError *error = nil;
    return [NSJSONSerialization dataWithJSONObject:@{@"method" : [self method], @"params" : [self params]}
                                    options:0 error:&error];
}

- (BOOL)request:(SBRequestOperation *)request didFinishWithResponse:(SBResponse *)response
{
    return YES;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[SBRequestOperation class]]) {
        return NO;
    } else {
        SBRequestOperation *otherRequest = (SBRequestOperation *)other;
        return [otherRequest->token isEqualToString:self->token] && [otherRequest.GUID isEqualToString:self.GUID];
    }
}

@end

#pragma mark -

@implementation SBLoginRequest

- (instancetype)init
{
    return [self initWithToken:nil comanyLogin:nil endpoint:kSBLoginEndpoint];
}

- (instancetype)initWithToken:(NSString *)_token comanyLogin:(NSString *)companyLogin
{
    return [self initWithToken:_token comanyLogin:companyLogin endpoint:kSBLoginEndpoint];
}

@end
