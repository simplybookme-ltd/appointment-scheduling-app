//
//  SBGetClientRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBGetClientRequest : SBRequestOperation

@property (nonatomic, copy) NSString *clientID;

@end

NS_ASSUME_NONNULL_END