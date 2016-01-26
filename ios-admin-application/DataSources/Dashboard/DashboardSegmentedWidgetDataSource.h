//
//  DashboardSegmentedWidgetDataSource.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DashboardAbstractWidgetDataSource.h"
#import "DashboardSegmentDataSource.h"

extern NSString * const kDashboardSegmentedWidgetHeaderSupplementaryKind;
extern NSString * const kDashboardSegmentedWidgetHeaderSupplementaryReuseIdentifier;

@class DashboardSegmentedWidgetDataSource;

@protocol DashboardSegmentedWidgetDataSourceDelegate <DashboardAbstractWidgetDataSourceDelegate>

- (void)dashboardSegmentedWidget:(DashboardSegmentedWidgetDataSource *)widget didSelectSegmentWithIndex:(NSUInteger)selectedSegmentIndex previouslySelectedSegmentIndex:(NSUInteger)previouslySelectedIndex;

@end

@interface DashboardSegmentedWidgetDataSource : DashboardAbstractWidgetDataSource

@property (nonatomic, readonly) NSArray *segments;
@property (nonatomic, readonly) DashboardSegmentDataSource *selectedSegment;
@property (nonatomic, readonly) NSUInteger selectedSegmentIndex;
@property (nonatomic, weak) NSObject<DashboardSegmentedWidgetDataSourceDelegate> *delegate;

- (void)addSegmentDataSource:(DashboardSegmentDataSource *)segmentDataSource;
- (void)selectSegmentAtIndex:(NSUInteger)segmentIndex;

@end
