//
//  ACHAdditionalFieldTableViewCell.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 04.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ACHAdditionalFieldStatus)
{
    ACHAdditionalFieldRequiredStatus,
    ACHAdditionalFieldNoStatus,
    ACHAdditionalFieldNotValidStatus
};

@interface ACHAdditionalFieldTableViewCell : UITableViewCell

@property (nonatomic, weak, nullable) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak, nullable) IBOutlet UILabel *valueLabel;
@property (nonatomic, copy, nullable) void (^updateHandler)();

- (nullable UISwitch *)switchWithAction:(void (^ _Nullable)(NSNumber * _Nullable value))action;
- (void)setStatus:(NSInteger)status;

@end
