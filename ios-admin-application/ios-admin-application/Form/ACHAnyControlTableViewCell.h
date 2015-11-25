//
//  ACHAnyControlTableViewCell.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 05.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ACHAnyControlTableViewCell <NSObject>

@property (nonatomic, readonly) UIResponder *control;

@end
