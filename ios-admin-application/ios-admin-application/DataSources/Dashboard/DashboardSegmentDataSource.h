//
//  DashboardSectionDataSource.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBRequest.h"

@class DashboardSegmentedWidgetDataSource;

@interface DashboardSegmentDataSource : NSObject

@property (atomic, getter=isLoading) BOOL loading;
@property (atomic, getter=isDataLoaded) BOOL dataLoaded;
@property (atomic, getter=isDataEmpty) BOOL dataEmpty;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, weak) DashboardSegmentedWidgetDataSource *parent;

- (SBRequest *)dataLoadingRequest;

@end
