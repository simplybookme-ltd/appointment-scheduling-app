//
//  LSWeekCollectionViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 10.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "LSWeekCollectionViewCell.h"

@interface LSWeekCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIView *labelsContainer;
@property (nonatomic, weak) IBOutlet UIView *marker1View;
@property (nonatomic, weak) IBOutlet UILabel *weekday1Label;
@property (nonatomic, weak) IBOutlet UILabel *day1Label;
@property (nonatomic, weak) IBOutlet UIView *marker2View;
@property (nonatomic, weak) IBOutlet UILabel *day2Label;

@end

@implementation LSWeekCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.day1Label.textColor = [UIColor whiteColor];
    self.weekday1Label.textColor = [UIColor whiteColor];
    self.marker1View.backgroundColor = [UIColor clearColor];
    self.day2Label.textColor = [UIColor whiteColor];
    self.marker2View.backgroundColor = [UIColor clearColor];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.day1Label.textColor = [UIColor whiteColor];
    self.weekday1Label.textColor = [UIColor whiteColor];
    self.marker1View.backgroundColor = [UIColor clearColor];
    self.day2Label.textColor = [UIColor whiteColor];
    self.marker2View.backgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.marker1View.layer.cornerRadius = self.marker1View.frame.size.width / 2.;
    self.marker2View.layer.cornerRadius = self.marker2View.frame.size.width / 2.;
}

- (void)showWeekday
{
    self.labelsContainer.hidden = NO;
    self.day2Label.hidden = YES;
    self.marker2View.hidden = YES;
}

- (void)hideWeekday
{
    self.labelsContainer.hidden = YES;
    self.day2Label.hidden = NO;
    self.marker2View.hidden = NO;
}

- (void)setDay:(NSString *)day weekday:(NSString *)weekday
{
    self.day1Label.text = day;
    self.day2Label.text = day;
    self.weekday1Label.text = weekday;
}

- (void)setTextColor:(UIColor *)color
{
    self.day1Label.textColor = color;
    self.day2Label.textColor = color;
    self.weekday1Label.textColor = color;
}

- (void)setMarkerColor:(UIColor *)color
{
    self.marker1View.backgroundColor = color;
    self.marker2View.backgroundColor = color;
}

@end
