//
//  initToMainSegue.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InitToMainSegue : UIStoryboardSegue

@end

@interface InitToMainAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, getter=isDismiss) BOOL dismiss;

@end
