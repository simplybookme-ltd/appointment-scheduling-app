//
//  PieChartCollectionViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "PieChartCollectionViewCell.h"

@interface PieChartCollectionViewCell ()
{
    NSMutableArray *slices;
}

@property (nonatomic, weak) IBOutlet UIView *legendContainer;
@property (nonatomic, strong) NSLayoutConstraint *bottomLegendConstraint;

@end

@implementation PieChartCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    slices = [NSMutableArray array];
    self.primaryValueLabel.layer.cornerRadius = self.primaryValueLabel.frame.size.width / 2.;
    self.primaryValueLabel.clipsToBounds = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.primaryValueLabel.layer.cornerRadius = self.primaryValueLabel.frame.size.width / 2.;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    for (UIView *subview in self.legendContainer.subviews) {
        [subview removeFromSuperview];
    }
    [slices removeAllObjects];
}

- (void)addValue:(NSNumber *)value withLabel:(NSString *)text color:(UIColor *)color
{
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = self.primaryValueLabel.font;
    label.textColor = self.primaryValueLabel.textColor;
    label.text = text;
    [self.legendContainer addSubview:label];
    
    UIView *colorSquare = [UIView new];
    colorSquare.translatesAutoresizingMaskIntoConstraints = NO;
    colorSquare.backgroundColor = color;
    [self.legendContainer addSubview:colorSquare];
    
    [self.legendContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[colorSquare(==15)]-[label]|"
                                                                                 options:0 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(colorSquare, label)]];
    [self.legendContainer addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:colorSquare
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1 constant:0]];
    if (slices.count == 0) {
        [self.legendContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[colorSquare(==15)]"
                                                                                 options:0 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(colorSquare)]];
    }
    else {
        UIView *topView = slices.lastObject;
        [self.legendContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topView]-[colorSquare(==15)]"
                                                                                 options:0 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(colorSquare, topView)]];
    }
    
    if (self.bottomLegendConstraint) {
        self.bottomLegendConstraint.active = NO;
    }
    self.bottomLegendConstraint = [NSLayoutConstraint constraintWithItem:colorSquare
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.legendContainer
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1 constant:0];
    [self.legendContainer addConstraint:self.bottomLegendConstraint];
    
    [slices addObject:colorSquare];
}

@end
