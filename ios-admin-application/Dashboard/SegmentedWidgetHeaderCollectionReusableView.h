//
//  SegmentedWidgetHeaderCollectionReusableView.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TitledWidgetHeaderCollectionReusableView.h"

@interface SegmentedWidgetHeaderCollectionReusableView : WidgetHeaderCollectionReusableView

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;

- (void)setTitle:(NSString *)title;

@end
