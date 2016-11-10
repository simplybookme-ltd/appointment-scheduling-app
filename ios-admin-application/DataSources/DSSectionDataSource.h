//
//  ACHHistoryDetailViewDataSources.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 11.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SBAdditionalField.h"

@class DSSectionRow;

@interface DSSectionDataSource : NSObject

@property (nonatomic) CGFloat estimatedRowHeight;
@property (nonatomic, copy) NSString *sectionTitle;
@property (nonatomic, readonly) NSArray <DSSectionRow *> *items;
@property (nonatomic, copy) NSString *cellReuseIdentifier;

- (void)setItems:(NSArray <DSSectionRow *> *)items;
- (void)addItem:(DSSectionRow *)item;
- (NSString *)cellReuseIdentifierForIndexPath:(NSIndexPath *)indexPath;
- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

@end

#pragma mark -

@interface DSSectionRow : NSObject

@property (nonatomic, copy) NSString *cellReuseIdentifier;

- (CGFloat)rowHeight:(CGFloat)defaultHeight maxWidth:(CGFloat)maxWidth;

@end

#pragma mark -

@interface TextValueRow : DSSectionRow

@property (nonatomic, copy) NSString *value;

+ (instancetype)rowWithValue:(NSString *)value;

@end

#pragma mark -

@interface KeyValueRow : DSSectionRow

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) UIView *accessoryView;

+ (instancetype)rowWithKey:(NSString *)key value:(NSString *)value;

@end

#pragma mark -

@interface ActionRow : DSSectionRow

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *iconName;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *iconTintColor;
@property (nonatomic, copy) void (^action)(UIViewController *controller);
@property (nonatomic, strong) UIView *accessoryView;

+ (instancetype)actionRowWithTitle:(NSString *)title iconName:(NSString *)iconName;

@end

#pragma mark -

@interface AdditionalFieldRow : DSSectionRow

@property (nonatomic, strong) NSObject<SBAdditionalFieldProtocol> *field;

+ (instancetype)rowWithAdditionalField:(NSObject<SBAdditionalFieldProtocol> *)field;

@end

