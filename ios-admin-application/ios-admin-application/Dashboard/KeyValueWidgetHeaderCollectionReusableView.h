//
//  KeyValueWidgetHeaderCollectionReusableView.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TitledWidgetHeaderCollectionReusableView.h"

@interface KeyValueWidgetHeaderCollectionReusableView : WidgetHeaderCollectionReusableView

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *keyLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

@end
