//
//  ACHAdditionalFieldEditorController.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 04.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACHAdditionalFieldTableViewCell.h"
#import "SBAdditionalField.h"

@interface ACHAdditionalFieldEditorController : UITableViewController

+ (void)configureAdditionalFieldCell:(ACHAdditionalFieldTableViewCell *)cell forField:(NSObject<SBAdditionalFieldProtocol> *)field;
+ (instancetype)editControllerForField:(SBAdditionalField *)field;

@end
