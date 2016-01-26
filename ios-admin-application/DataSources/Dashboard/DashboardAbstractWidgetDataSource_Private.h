//
//  DashboardAbstractWidgetDataSource_Private.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#ifndef DashboardAbstractWidgetDataSource_Private_h
#define DashboardAbstractWidgetDataSource_Private_h

#import "SBRequest.h"

@interface DashboardAbstractWidgetDataSource ()

@property (nonatomic, readwrite) BOOL loading;
@property (nonatomic, readwrite) NSError *error;
@property (nonatomic, readwrite) BOOL dataLoaded;
@property (nonatomic, readwrite) BOOL dataEmpty;

- (SBRequest *)dataLoadingRequest;
- (void)reloadData;

@end


#endif /* DashboardAbstractWidgetDataSource_Private_h */
