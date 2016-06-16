//
//  FilterListSelectorTableViewCell.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.02.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilterListSelectorTableViewCell : UITableViewCell

@property (nonatomic, weak, nullable) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak, nullable) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak, nullable) IBOutlet UIView *colorMarkView;

@end
