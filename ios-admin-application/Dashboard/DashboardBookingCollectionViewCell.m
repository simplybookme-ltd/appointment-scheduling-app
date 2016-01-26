//
//  DashboardBookingCollectionViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 30.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardBookingCollectionViewCell.h"
#import "UITraitCollection+SimplyBookLayout.h"

@interface DashboardBookingCollectionViewCell ()
{
    NSMutableArray *wideLayoutConstraints;
    NSMutableArray *compactLayoutConstraints;
}

@property (nonatomic, weak) IBOutlet UIButton *disclosureButton;

@end

@implementation DashboardBookingCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    for (NSLayoutConstraint *constraint in self.contentView.constraints) {
        if (constraint.firstItem != self.disclosureButton && constraint.secondItem != self.disclosureButton) {
            constraint.active = NO;
        }
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if ([self.traitCollection isWideLayout]) {
        [NSLayoutConstraint deactivateConstraints:[self compactLayoutConstraints]];
        [NSLayoutConstraint activateConstraints:[self wideLayoutConstraints]];
    }
    else {
        [NSLayoutConstraint deactivateConstraints:[self wideLayoutConstraints]];
        [NSLayoutConstraint activateConstraints:[self compactLayoutConstraints]];
    }
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact
        || self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)
    { // iPhone
        self.bookingDetailsLabel.font = [self.bookingDetailsLabel.font fontWithSize:15.];
    }
    else { // iPad
        self.bookingDetailsLabel.font = [self.bookingDetailsLabel.font fontWithSize:17.];
    }
}

- (NSArray *)wideLayoutConstraints
{
    if (!wideLayoutConstraints) {
        wideLayoutConstraints = [NSMutableArray array];
        [wideLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(5)-[_dateTimeLabel]"
                                                                                           options:0 metrics:nil
                                                                                             views:NSDictionaryOfVariableBindings(_dateTimeLabel)]];
        [wideLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(240)-[_bookingDetailsLabel]-(5)-[_performerLabel(>=150)]-(35)-|"
                                                                                           options:0 metrics:nil
                                                                                             views:NSDictionaryOfVariableBindings(_bookingDetailsLabel, _performerLabel)]];
        [wideLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:self.dateTimeLabel
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.contentView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1 constant:0]];
        [wideLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:self.bookingDetailsLabel
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.contentView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1 constant:0]];
        [wideLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:self.performerLabel
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.contentView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1 constant:0]];
    }
    return wideLayoutConstraints;
}

- (NSArray *)compactLayoutConstraints
{
    if (!compactLayoutConstraints) {
        compactLayoutConstraints = [NSMutableArray array];
        [compactLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(5)-[_dateTimeLabel]"
                                                                                              options:0 metrics:nil
                                                                                                views:NSDictionaryOfVariableBindings(_dateTimeLabel)]];
        [compactLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(5)-[_bookingDetailsLabel]-(5)-[_performerLabel]-(35)-|"
                                                                                              options:0 metrics:nil
                                                                                                views:NSDictionaryOfVariableBindings(_bookingDetailsLabel, _performerLabel)]];
        [compactLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(5)-[_dateTimeLabel]"
                                                                                              options:0 metrics:nil
                                                                                                views:NSDictionaryOfVariableBindings(_dateTimeLabel)]];
        [compactLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_bookingDetailsLabel]-(5)-|"
                                                                                              options:0 metrics:nil
                                                                                                views:NSDictionaryOfVariableBindings(_bookingDetailsLabel)]];
        [compactLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_performerLabel]-(5)-|"
                                                                                              options:0 metrics:nil
                                                                                                views:NSDictionaryOfVariableBindings(_performerLabel)]];
    }
    return compactLayoutConstraints;
}

@end
