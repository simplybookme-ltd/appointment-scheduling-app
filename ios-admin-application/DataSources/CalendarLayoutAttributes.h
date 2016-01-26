//
//  CalendarLayoutAttributes.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 15.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CalendarLayoutAttributes : UICollectionViewLayoutAttributes <NSCopying>

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic) BOOL stickyX;
@property (nonatomic) BOOL stickyY;
@property (nonatomic) CGFloat cornerRadius;

@end

@interface CalendarLayoutAttributes (CalendarGridCollectionViewLayout)

@property (nonatomic) BOOL xAdjusted;
@property (nonatomic) CGFloat startOffset;
@property (nonatomic) CGFloat duration;

@end
