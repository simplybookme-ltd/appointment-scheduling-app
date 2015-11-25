//
//  DashboardSectionDataSource.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardSegmentDataSource.h"
#import "SBSession.h"
#import "DashboardSegmentedWidgetDataSource.h"

@interface DashboardSegmentDataSource ()

@end

@implementation DashboardSegmentDataSource

- (SBRequest *)dataLoadingRequest
{
    NSAssertNotImplemented();
    return nil;
}

@end
