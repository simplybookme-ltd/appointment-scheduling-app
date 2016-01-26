//
//  UITraitCollection+SimplyBookLayout.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITraitCollection (SimplyBookLayout)

/**
 * iPhone landscape and iPad
 */
- (BOOL)isWideLayout;

@end
