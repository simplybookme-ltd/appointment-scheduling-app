//
//  BookingApproveStatusTableViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "BookingApproveStatusTableViewCell.h"

@implementation BookingApproveStatusTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)approveAction:(id)sender
{
    if (self.approveAction) {
        self.approveAction();
    }
}

- (IBAction)cancelAction:(id)sender
{
    if (self.cancelAction) {
        self.cancelAction();
    }
}

@end
