//
//  PendingBookingCollectionViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PendingBookingAction)
{
    PendingBookingShowOptionsAction,
    PendingBookingViewAction,
    PendingBookingApproveAction,
    PendingBookingCancelAction
};

@interface PendingBookingCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak, nullable) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak, nullable) IBOutlet UILabel *serviceLabel;
@property (nonatomic, weak, nullable) IBOutlet UILabel *performerLabel;
@property (nonatomic, weak, nullable) IBOutlet UILabel *clientLabel;
@property (nonatomic, copy, nullable) void (^action)(PendingBookingCollectionViewCell * _Nonnull cell, PendingBookingAction action);

- (void)showOptions;
- (void)hideOptions;
- (void)showActivityIndicator;
- (void)hideActivityIndicator;

@end
