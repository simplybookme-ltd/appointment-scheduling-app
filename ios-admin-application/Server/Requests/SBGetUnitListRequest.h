//
//  SBGetUnitList.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 29.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetUnitListRequest : SBRequestOperation

/// YES by default
@property (nonatomic) BOOL visibleOnly;
/// YES by default
@property (nonatomic) BOOL asArray;

@end
