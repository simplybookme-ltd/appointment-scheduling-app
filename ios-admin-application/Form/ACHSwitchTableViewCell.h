//
//  ACHSwitchTableViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACHAnyControlTableViewCell.h"

@interface ACHSwitchTableViewCell : UITableViewCell <ACHAnyControlTableViewCell>

@property (nonatomic, strong, readonly) UISwitch *switcher;

@end
