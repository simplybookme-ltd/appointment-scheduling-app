//
//  ACHRightDetailsTableViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 31.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACHRightDetailsTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *keyLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
