//
//  SBRequestsGroup.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 21.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBRequestOperation.h"

@interface SBRequestsGroup : NSBlockOperation <SBRequestProtocol>

@property (nonatomic) SBCachePolicy cachePolicy;

- (NSArray *)requests;
- (void)addRequest:(SBRequest *)request;
- (void)removeRequest:(SBRequest *)request;

@end
