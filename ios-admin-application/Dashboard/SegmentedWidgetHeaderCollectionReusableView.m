//
//  SegmentedWidgetHeaderCollectionReusableView.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SegmentedWidgetHeaderCollectionReusableView.h"

@interface SegmentedWidgetHeaderCollectionReusableView ()

@property (nonatomic, weak) IBOutlet UIView *adjustmentContainerView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *titleTopPositionConstraint;
@property (nonatomic, strong) NSLayoutConstraint *segmentedControlTopPositionConstraint;

@end

@implementation SegmentedWidgetHeaderCollectionReusableView

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.segmentedControlTopPositionConstraint = [NSLayoutConstraint constraintWithItem:self.segmentedControl
                                                                              attribute:NSLayoutAttributeTop
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.adjustmentContainerView
                                                                              attribute:NSLayoutAttributeTop
                                                                             multiplier:1 constant:0];
    [self.adjustmentContainerView addConstraint:self.segmentedControlTopPositionConstraint];
    self.segmentedControlTopPositionConstraint.active = NO;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.segmentedControlTopPositionConstraint.active = NO;
    self.titleTopPositionConstraint.active = YES;
    [self.segmentedControl removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
    self.titleTopPositionConstraint.active = (title != nil);
    self.segmentedControlTopPositionConstraint.active = (title == nil);
}

@end
