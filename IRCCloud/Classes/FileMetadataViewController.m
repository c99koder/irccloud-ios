//
//  FileMetadataViewController.m
//
//  Copyright (C) 2014 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "FileMetadataViewController.h"
#import "ImageViewController.h"
#import "AppDelegate.h"
#import "UIColor+IRCCloud.h"

@implementation FileMetadataViewController

- (id)initWithUploader:(FileUploader *)uploader {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        uploader.metadatadelegate = self;
        self->_uploader = uploader;
        self.navigationItem.title = @"Upload a File";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonPressed:)];
    }
    return self;
}

-(void)fileUploadWillUpload:(NSUInteger)bytes mimeType:(NSString *)mimeType {
    if(bytes < 1024) {
        self->_metadata = [NSString stringWithFormat:@"%lu B • %@", (unsigned long)bytes, mimeType];
    } else {
        int exp = (int)(log(bytes) / log(1024));
        self->_metadata = [NSString stringWithFormat:@"%.1f %cB • %@", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp -1], mimeType];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

-(void)saveButtonPressed:(id)sender {
    self->_done = YES;
    [self.tableView endEditing:YES];
    [self->_uploader setFilename:self->_filename.text message:self->_msg.text];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self performSelector:@selector(_resetStatusBar) withObject:nil afterDelay:0.1];
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    if(!parent && !_done)
        [self->_uploader cancel];
}

-(void)_resetStatusBar {
    [[UIApplication sharedApplication] setStatusBarStyle:[UIColor isDarkTheme]?UIStatusBarStyleLightContent:UIStatusBarStyleDefault];
}

-(void)cancelButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self->_uploader cancel];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self performSelector:@selector(_resetStatusBar) withObject:nil afterDelay:0.1];
}

-(void)showCancelButton {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(self->_uploader) {
        if(self.navigationController.viewControllers.count == 1) {
            self.navigationController.navigationBar.clipsToBounds = YES;
            
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        } else {
            self.navigationController.navigationBar.clipsToBounds = NO;
            [self.navigationController setNavigationBarHidden:NO animated:NO];
        }
    }
    
    if(!_filename.text.length)
        self->_filename.text = self->_uploader.originalFilename;
    if(!_metadata) {
        if(self->_uploader.mimeType.length)
            self->_metadata = [NSString stringWithFormat:@"Calculating size… • %@", _uploader.mimeType];
        else
            self->_metadata = @"Calculating size…";
    }
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self->_filename = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 3, 22)];
    self->_filename.textAlignment = NSTextAlignmentRight;
    self->_filename.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_filename.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self->_filename.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_filename.keyboardType = UIKeyboardTypeDefault;
    self->_filename.adjustsFontSizeToFitWidth = YES;
    self->_filename.returnKeyType = UIReturnKeyDone;
    self->_filename.delegate = self;
    
    self->_msg = [[UITextView alloc] initWithFrame:CGRectZero];
    self->_msg.text = @"";
    self->_msg.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_msg.backgroundColor = [UIColor clearColor];
    self->_msg.returnKeyType = UIReturnKeyDone;
    self->_msg.delegate = self;
    self->_msg.font = self->_filename.font;
    self->_msg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_msg.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"]) {
        self->_msg.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else {
        self->_msg.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    
    self->_imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self->_imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_imageView.contentMode = UIViewContentModeScaleAspectFit;
    if(@available(iOS 11, *))
        self->_imageView.accessibilityIgnoresInvertColors = YES;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if(!self.view.backgroundColor)
        self.view.backgroundColor = self.tableView.backgroundColor = [UIColor colorWithRed:0.937255 green:0.937255 blue:0.956863 alpha:1];
}

- (void)setURL:(NSString *)url {
    self->_url = url;
}

- (void)setFilename:(NSString *)filename metadata:(NSString *)metadata {
    self->_filename.text = filename;
    self->_filename.enabled = NO;
    self->_metadata = metadata;
    [self.tableView reloadData];
}

-(void)setImage:(UIImage *)image {
    CGFloat width = image.size.width, height = image.size.height;
    
    if(width > self.tableView.frame.size.width) {
        height *= self.tableView.frame.size.width / width;
    }
    
    if(height > 240) {
        height = 240;
    }
    
    self->_imageView.image = image;
    self->_imageHeight = height;
    
    [self.tableView reloadData];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if(self->_imageView)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    else
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [self.tableView endEditing:YES];
        return NO;
    }
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if(self->_imageView)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    else
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];

    if(textField.text.length) {
        textField.selectedTextRange = [textField textRangeFromPosition:textField.beginningOfDocument
                                                            toPosition:([textField.text rangeOfString:@"."].location != NSNotFound)?[textField positionFromPosition:textField.beginningOfDocument offset:[textField.text rangeOfString:@"." options:NSBackwardsSearch].location]:textField.endOfDocument];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.tableView endEditing:YES];
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if(!_imageView)
        section++;
    
    if(section == 0)
        return _imageHeight;
    else if(section == 2)
        return ([UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize * 2) + 32;
    else
        return [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize + 32;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self->_imageView)?3:2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(self->_imageView && section > 0)
        section--;
    
    switch (section) {
        case 1:
            return @"Message (optional)";
    }
    return nil;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,24)];
    UILabel *label;
    if(@available(iOS 11, *)) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(16 + self.view.safeAreaInsets.left,0,self.view.frame.size.width - 32, 20)];
    } else {
        label = [[UILabel alloc] initWithFrame:CGRectMake(16,0,self.view.frame.size.width - 32, 20)];
    }
    label.text = [self tableView:tableView titleForHeaderInSection:section].uppercaseString;
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [header addSubview:label];
    return header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize + 32;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == ((self->_imageView)?1:0))
        return _metadata;
    else
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    NSString *identifier = [NSString stringWithFormat:@"uploadcell-%li-%li", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailTextLabel.text = nil;
    cell.backgroundView = nil;
    cell.backgroundColor = [UITableViewCell appearance].backgroundColor;
    
    if(!_imageView)
        section++;
    
    switch(section) {
        case 0:
            cell.backgroundView = self->_imageView;
            cell.backgroundColor = [UIColor clearColor];
            break;
        case 1:
            cell.textLabel.text = @"Filename";
            cell.accessoryView = self->_filename;
            break;
        case 2:
            cell.textLabel.text = nil;
            [self->_msg removeFromSuperview];
            self->_msg.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:self->_msg];
            break;
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
    
    if(self->_imageView && _url && indexPath.section == 0) {
        ImageViewController *ivc = [[ImageViewController alloc] initWithURL:[NSURL URLWithString:self->_url]];
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        appDelegate.window.backgroundColor = [UIColor blackColor];
        appDelegate.window.rootViewController = ivc;
        [appDelegate.window insertSubview:appDelegate.slideViewController.view belowSubview:ivc.view];
        ivc.view.alpha = 0;
        [UIView animateWithDuration:0.5f animations:^{
            ivc.view.alpha = 1;
        } completion:^(BOOL finished){
            [UIApplication sharedApplication].statusBarHidden = YES;
        }];
    }
}

@end
