//
//  LSWeekCollectionViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 10.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LSWeekCollectionViewCell : UICollectionViewCell

- (void)showWeekday;
- (void)hideWeekday;

- (void)setDay:(NSString *)day weekday:(NSString *)weekday;
- (void)setTextColor:(UIColor *)color;
- (void)setMarkerColor:(UIColor *)color;

@end
