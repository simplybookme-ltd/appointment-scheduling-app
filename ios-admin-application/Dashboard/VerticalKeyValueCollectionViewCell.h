//
//  VerticalKeyValueCollectionViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VerticalKeyValueCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *keyLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

- (void)setImage:(UIImage *)image;

@end
