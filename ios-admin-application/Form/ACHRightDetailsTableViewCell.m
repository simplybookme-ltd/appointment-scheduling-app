//
//  ACHRightDetailsTableViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 31.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "ACHRightDetailsTableViewCell.h"

@interface ACHRightDetailsTableViewCell ()

@end

@implementation ACHRightDetailsTableViewCell

- (void)awakeFromNib
{
    self.activityIndicator.hidden = YES;
}

- (void)prepareForReuse
{
    self.activityIndicator.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
