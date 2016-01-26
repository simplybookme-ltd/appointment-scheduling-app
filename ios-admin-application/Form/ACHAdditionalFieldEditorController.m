//
//  ACHAdditionalFieldEditorController.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 04.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "ACHAdditionalFieldEditorController.h"
#import "ACHTextFieldTableViewCell.h"
#import "ACHTextViewTableViewCell.h"
#import "ACHPickerViewTableViewCell.h"
#import "ACHAnyControlTableViewCell.h"

@interface AdditionalFieldEditor : NSObject

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, copy) NSString *initialValue;
@property (nonatomic, readonly) NSString *cellReuseIdentifier;
@property (nonatomic, strong) NSArray *values;

+ (instancetype)editorForFieldType:(NSInteger)type;

- (void)didAppear;
- (void)configureTableView:(UITableView *)tableView;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (id)value;

@end

#pragma mark -

@interface ACHAdditionalFieldEditorController ()
{
    SBAdditionalField *field;
    AdditionalFieldEditor *fieldEditor;
}
@end

#pragma mark -

@implementation ACHAdditionalFieldEditorController

+ (void)configureAdditionalFieldCell:(ACHAdditionalFieldTableViewCell *)cell forField:(NSObject<SBAdditionalFieldProtocol> *)field
{
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
                field.value = value.boolValue ? kSBAdditionalFieldCheckboxValueTrue : kSBAdditionalFieldCheckboxValueFalse;
            }];
            if ([field.value isKindOfClass:[NSString class]]) {
                control.on = [field.value isEqualToString:kSBAdditionalFieldCheckboxValueTrue];
            } else {
                control.on = [field.value boolValue];
            }
            cell.accessoryView = control;
            cell.valueLabel.text = nil;
            if (field.isNull) {
                [cell setStatus:ACHAdditionalFieldNoStatus];
            }
            else if (!field.value) {
                [cell setStatus:ACHAdditionalFieldRequiredStatus];
            }
            else if (![field isValid]) {
                [cell setStatus:ACHAdditionalFieldNotValidStatus];
            }
        }
            break;
        default:
            NSAssert(NO, @"unexpected additional field type");
            break;
    }
}

+ (instancetype)editControllerForField:(SBAdditionalField *)field
{
    if (field.type.integerValue == SBAdditionalFieldCheckboxType) {
        return nil; // no editor controller for checkbox type
    }
    return [[self alloc] initWithEditor:[AdditionalFieldEditor editorForFieldType:field.type.integerValue] field:field];
}

- (instancetype)initWithEditor:(AdditionalFieldEditor *)_editor field:(SBAdditionalField *)_field
{
    self = [super initWithNibName:@"ACHAdditionalFieldEditorController" bundle:nil];
    if (self) {
        field = _field;
        fieldEditor = _editor;
        fieldEditor.initialValue = field.value;
        fieldEditor.values = field.values;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [fieldEditor configureTableView:self.tableView];
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    field.value = [fieldEditor value];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [fieldEditor didAppear];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [fieldEditor tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return field.title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (!field.isNull) {
        return NSLS(@"This field is mandatory", @"");
    }
    return nil;
}

@end

#pragma mark -

@interface AdditionalFieldTextEditor : AdditionalFieldEditor

@end

@interface AdditionalFieldTextareaEditor : AdditionalFieldEditor

@end

@interface AdditionalFieldDigitsEditor : AdditionalFieldTextEditor

@end

@interface AdditionalFieldSelectEditor : AdditionalFieldEditor <UIPickerViewDataSource, UIPickerViewDelegate>

@end

#pragma mark -

@implementation AdditionalFieldEditor

+ (instancetype)editorForFieldType:(NSInteger)type
{
    switch (type) {
        case SBAdditionalFieldTextType:
            return [AdditionalFieldTextEditor new];
        case SBAdditionalFieldTextareaType:
            return [AdditionalFieldTextareaEditor new];
        case SBAdditionalFieldDigitsType:
            return [AdditionalFieldDigitsEditor new];
        case SBAdditionalFieldSelectType:
            return [AdditionalFieldSelectEditor new];
        default:
            NSAssert(NO, @"unsupported field type %ld", (long)type);
            break;
    }
    return nil;
}

- (void)didAppear
{
    UITableViewCell<ACHAnyControlTableViewCell> *cell = (UITableViewCell<ACHAnyControlTableViewCell> *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [cell.control becomeFirstResponder];
}

- (NSString *)cellReuseIdentifier
{
    return @"cell";
}

- (void)configureTableView:(UITableView *)tableView
{
    self.tableView = tableView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:self.cellReuseIdentifier forIndexPath:indexPath];
}

- (id)value
{
    return nil;
}

@end

#pragma mark -

@implementation AdditionalFieldTextEditor

- (void)configureTableView:(UITableView *)tableView
{
    [super configureTableView:tableView];
    [tableView registerNib:[UINib nibWithNibName:@"ACHTextFieldTableViewCell" bundle:nil] forCellReuseIdentifier:self.cellReuseIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACHTextFieldTableViewCell *cell = (ACHTextFieldTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.textField.placeholder = @"";
    cell.textField.keyboardType = UIKeyboardTypeDefault;
    if (self.initialValue) {
        cell.textField.text = self.initialValue;
        self.initialValue = nil;
    }
    return cell;
}

- (id)value
{
    ACHTextFieldTableViewCell *cell = (ACHTextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cell.textField.text;
}

@end

@implementation AdditionalFieldTextareaEditor

- (void)configureTableView:(UITableView *)tableView
{
    [super configureTableView:tableView];
    [tableView registerNib:[UINib nibWithNibName:@"ACHTextViewTableViewCell" bundle:nil] forCellReuseIdentifier:self.cellReuseIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACHTextViewTableViewCell *cell = (ACHTextViewTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (self.initialValue) {
        cell.textView.text = self.initialValue;
        self.initialValue = nil;
    }
    return cell;
}

- (id)value
{
    ACHTextViewTableViewCell *cell = (ACHTextViewTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cell.textView.text;
}

@end

@implementation AdditionalFieldDigitsEditor

- (void)configureTableView:(UITableView *)tableView
{
    [super configureTableView:tableView];
    [tableView registerNib:[UINib nibWithNibName:@"ACHTextFieldTableViewCell" bundle:nil] forCellReuseIdentifier:self.cellReuseIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACHTextFieldTableViewCell *cell = (ACHTextFieldTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.textField.keyboardType = UIKeyboardTypeDecimalPad;
    return cell;
}

@end

@implementation AdditionalFieldSelectEditor

- (void)configureTableView:(UITableView *)tableView
{
    [super configureTableView:tableView];
    [tableView registerNib:[UINib nibWithNibName:@"ACHPickerViewTableViewCell" bundle:nil] forCellReuseIdentifier:self.cellReuseIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACHPickerViewTableViewCell *cell = (ACHPickerViewTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (!cell.pickerView.delegate) {
        cell.pickerView.delegate = self;
        cell.pickerView.dataSource = self;
        if (self.value) {
            [cell.pickerView selectRow:[self.values indexOfObject:self.value] inComponent:0 animated:NO];
        }
    }
    return cell;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.values.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.values[row];
}

- (id)value
{
    ACHPickerViewTableViewCell *cell = (ACHPickerViewTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return self.values[[cell.pickerView selectedRowInComponent:0]];
}

@end

