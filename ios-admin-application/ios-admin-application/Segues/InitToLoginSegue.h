//
//  InitToLoginSegue.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InitToLoginSegue : UIStoryboardSegue

@end

@interface InitToLoginAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, getter=isDismiss) BOOL dismiss;

@end