//
//  ACHTextFieldTableViewCell.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 31.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACHAnyControlTableViewCell.h"

@interface ACHTextFieldTableViewCell : UITableViewCell <ACHAnyControlTableViewCell>

@property (nonatomic, weak) IBOutlet UITextField *textField;

@end
