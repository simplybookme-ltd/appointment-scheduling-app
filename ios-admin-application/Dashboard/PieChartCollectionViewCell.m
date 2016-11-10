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
    [super awakeFromNib];
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
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.firstLineHeadIndent = 0;
    paragraphStyle.headIndent = 16;
    NSString *string = [NSString stringWithFormat:@"■ %@", text];
    NSDictionary *baseAttributes = @{NSFontAttributeName: [self.primaryValueLabel.font fontWithSize:self.primaryValueLabel.font.pointSize + 5],
                                     NSParagraphStyleAttributeName: paragraphStyle,
                                     NSForegroundColorAttributeName: self.primaryValueLabel.textColor};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string
                                                                                         attributes:baseAttributes];
    [attributedString addAttributes:@{NSForegroundColorAttributeName: color }
                              range:[string rangeOfString:@"■"]];
    [attributedString addAttributes:@{NSFontAttributeName: self.primaryValueLabel.font}
                              range:NSMakeRange([string rangeOfString:@"■"].location, string.length)];
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.attributedText = attributedString;
    label.preferredMaxLayoutWidth = self.legendContainer.frame.size.width - 10;
    label.minimumScaleFactor = .5;
    label.adjustsFontSizeToFitWidth = YES;
    [self.legendContainer addSubview:label];
    [label invalidateIntrinsicContentSize];
    [label layoutIfNeeded];
    
    [self.legendContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[label]|" options:0 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(label)]];
    if (slices.count == 0) {
        [self.legendContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]" options:0 metrics:nil
                                                                                       views:NSDictionaryOfVariableBindings(label)]];
    }
    else {
        UIView *topView = slices.lastObject;
        [self.legendContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topView]-[label]" options:0 metrics:nil
                                                                                       views:NSDictionaryOfVariableBindings(label, topView)]];
    }
    
    if (self.bottomLegendConstraint) {
        self.bottomLegendConstraint.active = NO;
    }
    self.bottomLegendConstraint = [NSLayoutConstraint constraintWithItem:label
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.legendContainer
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1 constant:0];
    [self.legendContainer addConstraint:self.bottomLegendConstraint];
    [slices addObject:label];
}

@end
