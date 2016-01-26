//
//  HorizontalKeyValueCollectionViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HorizontalKeyValueCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *keyLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

- (void)setImage:(UIImage *)image;

@end
