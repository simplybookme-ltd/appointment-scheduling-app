//
//  SBRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#ifndef SBRequest_h
#define SBRequest_h

@protocol SBRequestProtocol;

typedef NSOperation <SBRequestProtocol> SBRequest;

#import "SBRequestOperation.h"

#endif /* SBRequest_h */
