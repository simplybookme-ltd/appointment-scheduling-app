//
//  UITraitCollection+SimplyBookLayout.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "UITraitCollection+SimplyBookLayout.h"

@implementation UITraitCollection (SimplyBookLayout)

- (BOOL)isWideLayout
{
    return (self.horizontalSizeClass == UIUserInterfaceSizeClassCompact && self.verticalSizeClass == UIUserInterfaceSizeClassCompact)
    || (self.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.verticalSizeClass == UIUserInterfaceSizeClassCompact)
    || (self.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.verticalSizeClass == UIUserInterfaceSizeClassRegular);
}

@end
