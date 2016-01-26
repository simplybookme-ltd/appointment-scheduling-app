//
//  DashboardBookingCollectionViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 30.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DashboardBookingCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *dateTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *bookingDetailsLabel;
@property (nonatomic, weak) IBOutlet UILabel *performerLabel;

@end
