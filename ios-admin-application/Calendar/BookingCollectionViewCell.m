//
//  BookingCollectionViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 20.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "BookingCollectionViewCell.h"
#import "UIColor+SimplyBookColors.h"

@interface BookingCollectionViewCell ()

@property (nonatomic, strong, nullable) UIColor *color;
@property (nonatomic, strong, nullable) CALayer *statusLayer;
@property (nonatomic, weak, nullable) IBOutlet NSLayoutConstraint *textLabelTopLayoutConstraint;
@end

@implementation BookingCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    self.layer.masksToBounds = NO;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.alpha = 1.;
    self.textLabelTopLayoutConstraint.constant = 5;
}

- (void)setTimeText:(NSString *)time client:(nullable NSString *)client performer:(nullable NSString *)performer
            setvice:(nullable NSString *)service stausColor:(nullable UIColor *)statusColor
{
    NSParameterAssert(time != nil);
    NSString *statusString = (statusColor ? @"• " : @"");
    NSMutableString *string = [[NSMutableString alloc] initWithString:statusString];
    [string appendString:time];
    NSRange performerSubpartRange = NSRangeZero;
    NSRange clientSubpartRange = NSRangeZero;
    NSString *clue = @"\n";
    if (service) {
        [string appendFormat:@"%@%@", clue, service];
        clue = NSLS(@" by ", @"booking collection view cell (usage: [service] by [performance])");
    }
    if (performer) {
        performerSubpartRange = NSMakeRange(string.length, clue.length);
        [string appendFormat:@"%@%@", clue, performer];
    }
    clue = NSLS(@" for ", @"booking collection view cell (usage: [service] for [client]");
    if (client) {
        clientSubpartRange = NSMakeRange(string.length, clue.length);
        [string appendFormat:@"%@%@", clue, client];
    }
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    UIFontDescriptor *fontDescriptor = font.fontDescriptor;
    UIFont *boldFont = [UIFont fontWithDescriptor:[fontDescriptor fontDescriptorWithSize:fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold]
                                             size:font.pointSize];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string
                                                                           attributes:@{
                                                                                NSFontAttributeName : font
                                                                           }];
    NSDictionary *statusAttributes = @{
            NSStrokeWidthAttributeName : @-5.0,
            NSStrokeColorAttributeName : [UIColor whiteColor],
            NSForegroundColorAttributeName : statusColor ? statusColor : [UIColor clearColor],
            NSFontAttributeName : [UIFont boldSystemFontOfSize:font.pointSize + 7.],
            NSBaselineOffsetAttributeName : @(-1)
    };
    [attributedString setAttributes:statusAttributes
                              range:NSMakeRange(0, statusString.length)];
    if (statusColor) {
        CGSize size = [@"•" sizeWithAttributes:@{NSFontAttributeName : statusAttributes[NSFontAttributeName]}];
        CGSize size1 = [@"•" sizeWithAttributes:@{NSFontAttributeName : font}];
        self.textLabelTopLayoutConstraint.constant = size1.height - size.height + 5;
    }
    [attributedString setAttributes:@{NSFontAttributeName: boldFont} range:NSMakeRange(statusString.length, time.length)];
    if (performer) {
        [attributedString setAttributes:@{NSFontAttributeName : font,
                 NSForegroundColorAttributeName : [self.textLabel.textColor colorWithAlphaComponent:.7]}
                                  range:performerSubpartRange];
    }
    if (client) {
        [attributedString setAttributes:@{NSFontAttributeName : font,
                 NSForegroundColorAttributeName : [self.textLabel.textColor colorWithAlphaComponent:.7]}
                                  range:clientSubpartRange];
    }
    self.textLabel.attributedText = attributedString;
}

- (void)setBookingColor:(nonnull UIColor *)bookingColor canceled:(BOOL)canceled
{
    NSParameterAssert(bookingColor != nil);
    self.color = bookingColor;
    self.statusLayer.backgroundColor = self.color.CGColor;
    self.contentView.backgroundColor = [[self.color sb_colorLighterByPercent:.7] colorWithAlphaComponent:.6];
    UIColor *labelColor = [UIColor darkTextColor];
    if ([self.contentView.backgroundColor sb_colorBrightness] == SBColorDarkColorBrightness) {
        labelColor = [UIColor colorWithWhite:1. alpha:1.];
    }
    self.textLabel.textColor = labelColor;
    [self setCanceled:canceled];
}

- (void)setCanceled:(BOOL)canceled
{
    self.alpha = (canceled ? .5 : 1.);
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
    if (!self.statusLayer) {
        self.statusLayer = [CALayer layer];
        [self.layer addSublayer:self.statusLayer];
    }
    self.statusLayer.backgroundColor = self.color.CGColor;
    self.statusLayer.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds), 3, CGRectGetHeight(self.bounds));
}

@end
