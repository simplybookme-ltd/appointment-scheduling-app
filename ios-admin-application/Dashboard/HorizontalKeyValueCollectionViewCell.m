//
//  HorizontalKeyValueCollectionViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "HorizontalKeyValueCollectionViewCell.h"

@interface HorizontalKeyValueCollectionViewCell ()

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *imageToKeyConstraint;
@property (nonatomic, strong) NSLayoutConstraint *keyHorizontalConstraint;

@end

@implementation HorizontalKeyValueCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.keyHorizontalConstraint = [NSLayoutConstraint constraintWithItem:self.keyLabel
                                                                attribute:NSLayoutAttributeLeading
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.contentView
                                                                attribute:NSLayoutAttributeLeading
                                                               multiplier:1 constant:self.imageToKeyConstraint.constant];
    [self.contentView addConstraint:self.keyHorizontalConstraint];
    self.keyHorizontalConstraint.active = NO;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.keyHorizontalConstraint.active = NO;
    self.imageToKeyConstraint.active = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.keyHorizontalConstraint.active = (self.imageView.image == nil);
    self.imageToKeyConstraint.active = (self.imageView.image != nil);
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
    self.imageToKeyConstraint.active = (self.imageView.image != nil);
    self.keyHorizontalConstraint.active = (self.imageView.image == nil);
}

@end
