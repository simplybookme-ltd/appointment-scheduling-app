//
//  ACHAdditionalFieldTableViewCell.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 04.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "ACHAdditionalFieldTableViewCell.h"

@interface ACHAdditionalFieldTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, copy) void (^action)(id value);

@end

@implementation ACHAdditionalFieldTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:.5 constant:-(self.titleLabel.frame.origin.x)]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.valueLabel
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:.5 constant:-(self.titleLabel.frame.origin.x)]];
    self.separatorInset = UIEdgeInsetsMake(0, self.titleLabel.frame.origin.x, 0, 0);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
    self.action = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)switchValueChangedAction:(UISwitch *)sender
{
    if (self.action) {
        self.action(@(sender.on));
    }
    if (self.updateHandler) {
        self.updateHandler();
    }
}

- (UISwitch *)switchWithAction:(void (^)(NSNumber *))action
{
    UISwitch *control = [UISwitch new];
    [control addTarget:self action:@selector(switchValueChangedAction:) forControlEvents:UIControlEventValueChanged];
    self.action = action;
    return control;
}

- (void)setStatus:(NSInteger)status
{
    switch (status) {
        case ACHAdditionalFieldNoStatus:
            self.statusLabel.hidden = YES;
            break;
        case ACHAdditionalFieldRequiredStatus:
            self.statusLabel.hidden = NO;
            self.statusLabel.textColor = [UIColor colorWithRed:1 green:204./255. blue:102./255. alpha:1];
            break;
        case ACHAdditionalFieldNotValidStatus:
            self.statusLabel.hidden = NO;
            self.statusLabel.textColor = [UIColor colorWithRed:1 green:51./255. blue:0. alpha:1];
            break;
        default:
            NSAssert(NO, @"unexpected additional field status %ld", (long)status);
            break;
    }
}

@end
