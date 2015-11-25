//
//  ACHPickerTableViewCell.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 05.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACHAnyControlTableViewCell.h"

@interface ACHPickerViewTableViewCell : UITableViewCell <ACHAnyControlTableViewCell>

@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;

@end
