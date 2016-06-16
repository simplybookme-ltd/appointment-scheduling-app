//
//  AgendaViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AgendaViewController : UIViewController <UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak, nullable) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak, nullable) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

NS_ASSUME_NONNULL_END