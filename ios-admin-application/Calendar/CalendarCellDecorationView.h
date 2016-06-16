//
//  CalendarCellDecorationView.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 14.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHorizontalLineDecorationViewKind;

@interface CalendarCellDecorationView : UICollectionReusableView

+ (NSString *)kind;
+ (UIColor *)gridColor;

@end

NS_ASSUME_NONNULL_END