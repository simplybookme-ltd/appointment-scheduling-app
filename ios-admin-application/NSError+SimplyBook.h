//
//  NSError+SimplyBook.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 14.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (SimplyBook)

- (NSString *)message;
- (BOOL)isNetworkConnectionError;

@end
