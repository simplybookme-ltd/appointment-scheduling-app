//
//  BookingApproveStatusTableViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BookingApproveStatusTableViewCell : UITableViewCell

@property (nonatomic, weak, nullable) IBOutlet UILabel *statusLabel;
@property (nonatomic, copy, nullable) void (^approveAction)();
@property (nonatomic, copy, nullable) void (^cancelAction)();

@end
