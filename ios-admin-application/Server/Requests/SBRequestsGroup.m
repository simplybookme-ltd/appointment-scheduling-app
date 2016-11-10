//
//  SBRequestsGroup.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 21.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestsGroup.h"

@interface SBRequestsGroup () <SBRequestDelegate>
{
    NSString *GUID;
}

@property (nonatomic, strong) NSError *error;

@end

@implementation SBRequestsGroup

@synthesize GUID = GUID;
@synthesize delegate;
@synthesize callback;
@synthesize cachePolicy = _cachePolicy;
@synthesize predispatchBlock;

- (instancetype)init
{
    self = [super init];
    if (self) {
        GUID = [NSString stringWithFormat:@"%@-%@", NSStringFromClass([self class]), [[NSProcessInfo processInfo] globallyUniqueString]];
        __weak typeof (self) weakSelf = self;
        [self addExecutionBlock:^{
#ifdef DEBUG
            if (weakSelf.callback == nil) { // NSAssert generates compile warrning.
                [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd object:weakSelf file:[NSString stringWithUTF8String:__FILE__] lineNumber:__LINE__ description:@"no callback specified"];
            }
#endif
            SBResponse *responce = nil;
            if (weakSelf.error) {
                responce = [SBErrorResponse responseWithError:weakSelf.error requestGUID:weakSelf.GUID];
            } else {
                responce = [SBBooleanResponse booleanResponseWithValue:!weakSelf.cancelled requestGUID:weakSelf.GUID];
            }
            if ([weakSelf.delegate request:weakSelf didFinishWithResponse:responce] && weakSelf.callback != nil) {
                weakSelf.callback(responce);
            };
        }];
    }
    return self;
}

- (SBCachePolicy)cachePolicy
{
    return SBNoCachePolicy;
}

- (NSArray *)requests
{
    return self.dependencies;
}

- (void)addRequest:(SBRequest *)request
{
    NSParameterAssert(request != nil);
    NSParameterAssert(![request isKindOfClass:[self class]]); // group in group
    if (request == nil || [request isKindOfClass:[self class]]) {
        return;
    }
    request.delegate = self;
    [self addDependency:request];
}

- (void)removeRequest:(SBRequest *)request
{
    [self removeDependency:request];
}

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [[self class] new];
    copy.callback = self.callback;
    copy.delegate = self.delegate;
    for (SBRequest *request in self.dependencies) {
        [copy addRequest:[request copyWithToken:token]];
    }
    return copy;
}

- (BOOL)request:(SBRequest *)request didFinishWithResponse:(SBResponse *)response
{
    if (request == self) {
        return YES;
    }
    if (self.error) {
        return NO;
    }
    if (response.error) {
        self.error = response.error;
        [self cancel];
        if ([self.delegate request:self didFinishWithResponse:response]) {
            self.callback(response);
        };
        return NO;
    }
    [[SBCache cache] cacheResponse:response forRequest:request];
    return YES;
}

- (BOOL)shouldDispatchRequest:(SBRequest *)request
{
    return !self.cancelled;
}

- (NSString *)description
{
    NSMutableArray *description = [NSMutableArray array];
    for (NSOperation *operation in self.dependencies) {
        [description addObject:[operation description]];
    }
    return [NSMutableString stringWithFormat:@"%@:\n%@", NSStringFromClass([self class]), description];
    
}

@end
