//
//  ClientListViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocationsListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, nullable, weak) IBOutlet UITableView *tableView;
@property (nonatomic, nullable, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, nullable, copy) NSString *unitID;
@property (nonatomic, nullable, copy) void (^locationSelectedHandler)(NSDictionary * _Nonnull location);

@end
