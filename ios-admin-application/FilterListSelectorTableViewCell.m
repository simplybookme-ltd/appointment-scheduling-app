//
//  FilterListSelectorTableViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.02.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "FilterListSelectorTableViewCell.h"

@implementation FilterListSelectorTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.colorMarkView.layer.cornerRadius = self.colorMarkView.frame.size.width/2;
    self.colorMarkView.layer.masksToBounds = YES;
    self.colorMarkView.layer.borderWidth = 1;
    self.colorMarkView.layer.borderColor = [UIColor lightGrayColor].CGColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.colorMarkView.hidden = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
