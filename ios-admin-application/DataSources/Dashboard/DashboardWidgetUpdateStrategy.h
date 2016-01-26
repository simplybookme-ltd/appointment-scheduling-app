//
//  DashboardWidgetUpdateStrategy.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DashboardAbstractWidgetDataSource;

@interface DashboardWidgetUpdateStrategy : NSObject

+ (instancetype _Nullable)timerUpdateStrategyWithTimeInterval:(NSTimeInterval)timeInterval forWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget;
+ (instancetype _Nullable)notificationUpdateStrategyWithNotificationName:(NSString *_Nonnull)notificationName
                                                         observingObject:(id _Nullable)observingObject
                                                               forWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget;

- (void)widgetDidFinishDataLoading;
- (void)cancelUpdates;

@end
