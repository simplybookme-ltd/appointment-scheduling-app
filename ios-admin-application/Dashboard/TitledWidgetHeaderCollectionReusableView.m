//
//  TitledWidgetHeaderCollectionReusableView.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "TitledWidgetHeaderCollectionReusableView.h"

@interface TitledWidgetHeaderCollectionReusableView ()

@property (nonatomic, strong) NSLayoutConstraint *titleBottomConstraint;
@property (nonatomic, weak) IBOutlet UIView *adjustmentContainerView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *subtitleBottomConstraint;

@end

@implementation TitledWidgetHeaderCollectionReusableView

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.titleBottomConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.adjustmentContainerView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1 constant:0];
    [self.adjustmentContainerView addConstraint:self.titleBottomConstraint];
    self.titleBottomConstraint.active = NO;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.subtitleLabel.hidden = NO;
    self.subtitleBottomConstraint.active = YES;
    self.titleBottomConstraint.active = NO;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.mask.frame = self.bounds;
}

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle
{
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    self.subtitleLabel.hidden = (subtitle == nil);
    self.subtitleBottomConstraint.active = (subtitle != nil);
    self.titleBottomConstraint.active = (subtitle == nil);
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

@end

#pragma mark -

@implementation WidgetHeaderCollectionReusableView

- (void)awakeFromNib
{
    self.cornerRadius = 5;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    UIBezierPath *path =[UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds) + self.cornerRadius)];
    [path addArcWithCenter:CGPointMake(CGRectGetMinX(self.bounds) + self.cornerRadius, CGRectGetMinY(self.bounds) + self.cornerRadius)
                    radius:self.cornerRadius
                startAngle:M_PI endAngle:M_PI + M_PI_2
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(self.bounds) - self.cornerRadius, CGRectGetMinY(self.bounds))];
    [path addArcWithCenter:CGPointMake(CGRectGetMaxX(self.bounds) - self.cornerRadius, CGRectGetMinY(self.bounds) + self.cornerRadius)
                    radius:self.cornerRadius
                startAngle:M_PI + M_PI_2 endAngle:M_PI * 2
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds))];
    [path closePath];
    CAShapeLayer *mask = nil;
    if (self.layer.mask == nil) {
        mask = [CAShapeLayer layer];
        mask.path = path.CGPath;
        mask.fillColor = self.backgroundColor.CGColor;
        self.layer.mask = mask;
    }
    else {
        mask = (CAShapeLayer *)self.layer.mask;
        mask.path = path.CGPath;
        mask.fillColor = self.backgroundColor.CGColor;
    }
}

@end