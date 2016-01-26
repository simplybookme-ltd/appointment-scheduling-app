//
//  DashboardTitledWidgetDataSource.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DashboardAbstractWidgetDataSource.h"

extern NSString * const kDashboardTitledWidgetHeaderSupplementaryKind;
extern NSString * const kDashboardTitledWidgetHeaderSupplementaryReuseIdentifier;

@interface DashboardTitledWidgetDataSource : DashboardAbstractWidgetDataSource

@property (nonatomic, strong) NSString *subtitle;

@end
