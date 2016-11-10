//
//  VerticalKeyValueCollectionViewCell.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "VerticalKeyValueCollectionViewCell.h"

@interface VerticalKeyValueCollectionViewCell ()

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *imageToLabelVerticalConstraint;
@property (nonatomic, strong) NSLayoutConstraint *keyLabelVerticalConstraint;

@end

@implementation VerticalKeyValueCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.keyLabelVerticalConstraint = [NSLayoutConstraint constraintWithItem:self.keyLabel
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentView
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1 constant:self.imageToLabelVerticalConstraint.constant];
    [self.contentView addConstraint:self.keyLabelVerticalConstraint];
    self.keyLabelVerticalConstraint.active = NO;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.keyLabelVerticalConstraint.active = NO;
    self.imageToLabelVerticalConstraint.active = YES;
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
    self.imageToLabelVerticalConstraint.active = (image != nil);
    self.keyLabelVerticalConstraint.active = (image == nil);
}

@end
