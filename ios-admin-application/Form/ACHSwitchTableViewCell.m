//
//  ACHSwitchTableViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "ACHSwitchTableViewCell.h"

@implementation ACHSwitchTableViewCell

@synthesize switcher = _switcher;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _switcher = [UISwitch new];
        self.accessoryView = _switcher;
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _switcher = [UISwitch new];
        self.accessoryView = _switcher;
    }
    return self;
}

- (UISwitch *)switcher
{
    if (_switcher) {
        return _switcher;
    }
    _switcher = [UISwitch new];
    self.accessoryView = _switcher;
    return _switcher;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIResponder *)control
{
    return self.switcher;
}

@end
