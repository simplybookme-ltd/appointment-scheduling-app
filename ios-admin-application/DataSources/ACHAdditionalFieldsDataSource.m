//
//  ACHAdditionalFieldsDataSource.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 10.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "ACHAdditionalFieldsDataSource.h"
#import "ACHAdditionalFieldEditorController.h"
#import "ACHAdditionalFieldTableViewCell.h"

@interface ACHAdditionalFieldsDataSource ()

@property (nonatomic, strong) NSArray *additionalFields;
@property (nonatomic, weak, readwrite) UITableView *tableView;

@end

@implementation ACHAdditionalFieldsDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cellReuseIdentifier = @"additional-field-cell";
    }
    return self;
}

- (instancetype)initWithAdditionalFields:(NSArray *)additionalFields
{
    self = [super init];
    if (self) {
        self.additionalFields = additionalFields;
        self.cellReuseIdentifier = @"additional-field-cell";
    }
    return self;
}

- (void)setAdditionalFields:(NSArray *)additionalFields
{
    _additionalFields = additionalFields;
}

- (UINib *)nibForTableViewCell
{
    return [UINib nibWithNibName:@"ACHAdditionalFieldTableViewCell" bundle:nil];
}

- (void)setCellReuseIdentifier:(NSString *)cellReuseIdentifier
{
    _cellReuseIdentifier = cellReuseIdentifier;
    [self.tableView registerNib:[self nibForTableViewCell] forCellReuseIdentifier:_cellReuseIdentifier];
}

- (void)configureTableView:(UITableView *)tableView
{
    self.tableView = tableView;
    [tableView registerNib:[self nibForTableViewCell] forCellReuseIdentifier:self.cellReuseIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.additionalFields.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACHAdditionalFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseIdentifier forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(ACHAdditionalFieldTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SBAdditionalField *field = self.additionalFields[indexPath.row];
    [ACHAdditionalFieldEditorController configureAdditionalFieldCell:cell forField:field];
    if ([self isReadOnly]) {
        if (field.type.integerValue == SBAdditionalFieldCheckboxType) {
            UISwitch *control = [cell switchWithAction:nil];
            if ([field.value isKindOfClass:[NSString class]]) {
                control.on = [field.value isEqualToString:kSBAdditionalFieldCheckboxValueTrue];
            } else {
                control.on = [field.value boolValue];
            }
            cell.accessoryView = control;
            control.enabled = !self.readOnly;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else {
        cell.updateHandler = ^ {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        };
    }
}

@end
