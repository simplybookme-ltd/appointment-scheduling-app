//
//  ACHHistoryDetailViewDataSources.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 11.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "DSSectionDataSource.h"
#import "ACHKeyValueTableViewCell.h"
#import "ACHAdditionalFieldTableViewCell.h"
#import "ACHKeyValueTableViewCell.h"

@interface DSSectionRow ()

- (void)configureCell:(UITableViewCell *)cell;

@end

@interface DSSectionDataSource ()
{
    @protected
    NSMutableArray *items;
}
@end

@implementation DSSectionDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.estimatedRowHeight = 44.;
        items = [NSMutableArray array];
        self.cellReuseIdentifier = @"cell";
    }
    return self;
}

- (NSArray *)items
{
    return items;
}

- (void)addItem:(DSSectionRow *)item
{
    [items addObject:item];
}

- (void)setItems:(NSArray *)_items
{
    [items removeAllObjects];
    [items addObjectsFromArray:_items];
}

- (NSString *)cellReuseIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(self.cellReuseIdentifier != nil, @"section datasource not configured. please specify cell reuse identifier.");
    return [items[indexPath.row] cellReuseIdentifier] ? [items[indexPath.row] cellReuseIdentifier] : self.cellReuseIdentifier;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    DSSectionRow *item = items[indexPath.row];
    [item configureCell:cell];
}

@end

#pragma mark -

@implementation DSSectionRow

- (void)configureCell:(UITableViewCell *)cell
{
    NSAssertNotImplemented();
}

@end

#pragma mark -

@implementation ActionRow

+ (instancetype)actionRowWithTitle:(NSString *)title iconName:(NSString *)iconName
{
    ActionRow *action = [[self alloc] init];
    action.title = title;
    action.iconName = iconName;
    action.textColor = [UIColor blackColor];
    return action;
}

- (void)configureCell:(UITableViewCell *)cell
{
    cell.textLabel.text = self.title;
    cell.textLabel.textColor = (self.action != NULL ? self.tintColor : self.textColor);
    if (self.iconName) {
        cell.imageView.image = [[UIImage imageNamed:self.iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.imageView.tintColor = (self.iconTintColor ? self.iconTintColor : [UIColor grayColor]);
    } else {
        cell.imageView.image = nil;
    }
    cell.accessoryView = [self accessoryView];
}

@end

#pragma mark -

@implementation KeyValueRow

+ (instancetype)rowWithKey:(NSString *)key value:(NSString *)value
{
    KeyValueRow *row = [[self alloc] init];
    row.key = key;
    row.value = value;
    return row;
}

- (void)configureCell:(ACHKeyValueTableViewCell *)cell
{
    NSAssert([cell isKindOfClass:[ACHKeyValueTableViewCell class]], @"unsupported class. ACHKeyValueTableViewCell expected, %@ occurred", NSStringFromClass([cell class]));
    cell.titleLabel.text = [self key];
    cell.valueLabel.text = [self value];
    cell.accessoryView = [self accessoryView];
}

@end

#pragma mark -

@implementation AdditionalFieldRow

+ (instancetype)rowWithAdditionalField:(NSObject<SBAdditionalFieldProtocol> *)field
{
    AdditionalFieldRow *row = [self new];
    row.field = field;
    return row;
}

- (void)configureCell:(ACHAdditionalFieldTableViewCell *)cell
{
    NSObject<SBAdditionalFieldProtocol> *field = [self field];
    NSAssert([cell isKindOfClass:[ACHAdditionalFieldTableViewCell class]], @"unsupported class. ACHAdditionalFieldTableViewCell expected, %@ occurred", NSStringFromClass([cell class]));
    
    cell.titleLabel.text = field.title;
    if (!field.value && !field.isNull) {
        [cell setStatus:ACHAdditionalFieldRequiredStatus];
    } else if (!field.isNull && field.value) {
        if ([field isValid]) {
            [cell setStatus:ACHAdditionalFieldNoStatus];
        } else {
            [cell setStatus:ACHAdditionalFieldNotValidStatus];
        }
    } else if (field.isNull) {
        [cell setStatus:ACHAdditionalFieldNoStatus];
    }
    switch (field.type.integerValue) {
        case SBAdditionalFieldTextType:
        case SBAdditionalFieldTextareaType:
        case SBAdditionalFieldSelectType:
            cell.valueLabel.text = field.value;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case SBAdditionalFieldDigitsType:
            cell.valueLabel.text = [NSString stringWithFormat:@"%@", field.value ? field.value : @""];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case SBAdditionalFieldCheckboxType:
        {
            UISwitch *control = [cell switchWithAction:^(NSNumber *value) {
                field.value = @(value.boolValue);
            }];
            control.on = [field.value boolValue];
            cell.accessoryView = control;
            cell.valueLabel.text = nil;
            [cell setStatus:ACHAdditionalFieldNoStatus];
        }
            break;
        default:
            NSAssert(NO, @"unexpected additional field type");
            break;
    }
    
    if (field.type.integerValue == SBAdditionalFieldCheckboxType) {
        UISwitch *control = [cell switchWithAction:nil];
        control.on = ([field.value isKindOfClass:[NSString class]] ? [field.value isEqualToString:kSBAdditionalFieldCheckboxValueTrue] : [field.value boolValue]);
        cell.accessoryView = control;
        control.enabled = NO;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end