//
//  ACHPickerTableViewCell.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 05.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "ACHPickerViewTableViewCell.h"

@implementation ACHPickerViewTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIResponder *)control
{
    return self.pickerView;
}

@end
