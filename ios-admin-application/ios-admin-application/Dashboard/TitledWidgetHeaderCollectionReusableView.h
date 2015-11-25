//
//  TitledWidgetHeaderCollectionReusableView.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WidgetHeaderCollectionReusableView : UICollectionReusableView

@property (nonatomic) CGFloat cornerRadius;

@end

@interface TitledWidgetHeaderCollectionReusableView : WidgetHeaderCollectionReusableView 

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle;

@end
