//
//  ACHTextFieldTableViewCell.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 31.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "ACHTextFieldTableViewCell.h"

@implementation ACHTextFieldTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIResponder *)control
{
    return self.textField;
}

@end
