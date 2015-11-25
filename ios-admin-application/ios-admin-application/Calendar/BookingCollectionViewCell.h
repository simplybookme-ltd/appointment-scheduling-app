//
//  BookingCollectionViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 20.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BookingCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak, nullable) IBOutlet UILabel *textLabel;

- (void)setTimeText:(NSString *)time client:(nullable NSString *)client performer:(nullable NSString *)performer
            setvice:(nullable NSString *)service
         stausColor:(nullable UIColor *)statusColor;
- (void)setBookingColor:(UIColor *)bookingColor canceled:(BOOL)canceled;
- (void)setCanceled:(BOOL)canceled;

@end

NS_ASSUME_NONNULL_END
