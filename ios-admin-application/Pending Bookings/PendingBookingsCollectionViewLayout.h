//
//  PendingBookingsCollectionViewLayout.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PendingBookingsCollectionViewLayout : UICollectionViewFlowLayout

@property (nonatomic, weak, nullable) NSObject<UICollectionViewDataSource> *pendingBookingsDataSource;

@end
