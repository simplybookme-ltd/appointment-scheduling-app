//
//  PendingBookingCollectionViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "PendingBookingCollectionViewCell.h"
#import "UIColor+SimplyBookColors.h"

@interface PendingBookingCollectionViewCell ()
{
    CGFloat initialConstant;
}

@property (nonatomic, weak, nullable) IBOutlet NSLayoutConstraint *optionsLayoutConstraint;
@property (nonatomic, weak, nullable) IBOutlet UIButton *viewOptionButton;
@property (nonatomic, weak, nullable) IBOutlet UIButton *optionsButton;
@property (nonatomic, weak, nullable) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation PendingBookingCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    initialConstant = self.optionsLayoutConstraint.constant;
    self.optionsLayoutConstraint.constant = -(self.viewOptionButton.frame.size.width * 3 + initialConstant * 3);
    self.optionsButton.hidden = NO;
    self.activityIndicator.hidden = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.optionsLayoutConstraint.constant = -(self.viewOptionButton.frame.size.width * 3 + initialConstant * 3);
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (!selected) {
        [self hideOptions];
    }
}

- (IBAction)approveAction:(id)sender
{
    if (self.action) {
        self.action(self, PendingBookingApproveAction);
    }
}

- (IBAction)cancelAction:(id)sender
{
    if (self.action) {
        self.action(self, PendingBookingCancelAction);
    }
}

- (IBAction)viewAction:(id)sender
{
    if (self.action) {
        self.action(self, PendingBookingViewAction);
    }
}

- (IBAction)showOptionsAction:(id)sender
{
    if (self.action) {
        self.action(self, PendingBookingShowOptionsAction);
    }
}

- (void)showOptions
{
    self.optionsLayoutConstraint.constant = initialConstant;
    [self setNeedsUpdateConstraints];
    [UIView animateWithDuration:.25 delay:0
         usingSpringWithDamping:.8 initialSpringVelocity:.3 options:0
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)hideOptions
{
    self.optionsLayoutConstraint.constant = -(self.viewOptionButton.frame.size.width * 3 + initialConstant * 3);
    [self setNeedsUpdateConstraints];
    [UIView animateWithDuration:.25 delay:0
         usingSpringWithDamping:.8 initialSpringVelocity:.5 options:0
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)showActivityIndicator
{
    self.optionsButton.hidden = YES;
    self.activityIndicator.hidden = NO;
}

- (void)hideActivityIndicator
{
    self.optionsButton.hidden = NO;
    self.activityIndicator.hidden = YES;
}

@end
