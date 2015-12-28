//
//  ExamineTaskViewController.m
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import "ExamineTaskViewController.h"

#define COLLECTION_VIEW_SPACING 8.f

@interface ExamineTaskViewController ()

@end

@implementation ExamineTaskViewController

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(50.f, 50.f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return COLLECTION_VIEW_SPACING;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return COLLECTION_VIEW_SPACING;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 30;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* const Identifier = @"UserView";
    
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:Identifier forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255) / (CGFloat)255 green:arc4random_uniform(255) / (CGFloat)255 blue:arc4random_uniform(255) / (CGFloat)255 alpha:1.f];
    
    return cell;
}

- (BOOL)hasBitcoinAddress {
    return [[PFUser currentUser][@"address"] length];
}

- (void)setTask:(PFObject *)task {
    _task = task;
    
    self.navigationItem.title = task[@"title"];
    
    _contributions = task[@"committedPayments"];
    _myContribution = -1;
    
    for (PFObject* payment in task[@"committedPayments"]) {
        [payment fetchIfNeeded];
        _totalValue += [payment[@"amount"] integerValue];
        
        if ([payment[@"username"] isEqualToString:[PFUser currentUser].username]) {
            assert(!_hasContributed); // Should only have contributed once
            
            _hasContributed = YES;
            _myContribution = [payment[@"amount"] intValue];
        }
    }
}

- (IBAction)imageButtonPressed:(id)sender {
    // TODO - Go fullscreen
}

- (IBAction)claimPressed:(id)sender {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Are You Sure?" message:[NSString stringWithFormat:@"Are you sure you want to claim this task? You will have %i days to check in with the poster on your progress.", [_task[@"claimPeriod"] intValue]] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Claim" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        _task[@"claimDate"] = [NSDate date];
        _task[@"claimed"] = @YES;
        _task[@"claimee"] = [PFUser currentUser].username;
        
        NSLog(@"updating task");
        [_task saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            NSLog(@"updating user info");
            
            NSArray* claimee = [PFUser currentUser][@"claimee"];
            if (!claimee) {
                claimee = [NSArray arrayWithObject:_task.objectId];
            } else {
                claimee = [claimee arrayByAddingObject:_task.objectId];
            }
            [PFUser currentUser][@"claimee"] = claimee;
            
            [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                [_claimButton setTitle:@"Claimed" forState:UIControlStateNormal];
                _claimButton.enabled = NO;
                _contributeButton.enabled = NO;
                [_claimButton setTitleColor:nil forState:UIControlStateNormal];
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)textFieldChanged:(UITextField*)sender {
    if (sender.text.length) {
        _contributeAction.enabled = YES;
    } else {
        _contributeAction.enabled = NO;
    }
}

- (IBAction)contributePressed:(id)sender {
    if ([self hasBitcoinAddress]) {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"How much would you like to contribute?" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
            textField.placeholder = @"Enter a dollar amount";
        }];
        
        UIAlertAction* action = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertController addAction:action];
        
        UIAlertAction* contribute = [UIAlertAction actionWithTitle:@"Contribute" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            PFObject* newPayment = [PFObject objectWithClassName:@"Payment"];
            newPayment[@"username"] = [PFUser currentUser].username;
            newPayment[@"amount"] = @([alertController.textFields[0].text intValue]);
            NSArray* payments = [_task[@"committedPayments"] arrayByAddingObject:newPayment];
            _task[@"committedPayments"] = payments;
            
            UIAlertController* saving = [UIAlertController alertControllerWithTitle:@"Sending Your Contribution..." message:@"Please wait" preferredStyle:UIAlertControllerStyleAlert];
            [self presentViewController:saving animated:YES completion:^{
                NSLog(@"saving contribution");
                [_task saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    NSLog(@"saving user data");
                    
                    NSArray* contributions = [PFUser currentUser][@"contributor"];
                    if (!contributions) {
                        contributions = [NSArray arrayWithObject:_task.objectId];
                    } else {
                        contributions = [contributions arrayByAddingObject:_task.objectId];
                    }
                    [PFUser currentUser][@"contributor"] = contributions;
                    
                    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        [saving setTitle:@"Contribution Sent!"];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            _contributeButton.enabled = NO;
                            _myContribution = [newPayment[@"amount"] intValue];
                            [_contributeButton setTitle:[NSString stringWithFormat:@"You contributed $%ld", (long)_myContribution] forState:UIControlStateNormal];
                            [self dismissViewControllerAnimated:YES completion:nil];
                        });
                    }];
                    
                }];
            }];
        }];
        
        _contributeAction = contribute;
        contribute.enabled = NO;
        [alertController addAction:contribute];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"No Bitcoin Address" message:@"You must add or create a Bitcoin address in My Stuff before posting a new task." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Claim!" style:UIBarButtonItemStylePlain target:self action:@selector(claimPressed:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0 green:153.f/255.f blue:0 alpha:1.f];
    
    _descriptionTextView.textContainerInset = UIEdgeInsetsZero;
    
    _collectionView.backgroundColor = self.view.backgroundColor;
    
    if ([[PFUser currentUser].username isEqualToString:_task[@"poster"]]) {
        _titleLabel.text = @"You posted this task";
    } else {
        _titleLabel.text = [NSString stringWithFormat:@"Posted by: %@", _task[@"poster"]];
    }
    
    _contributionsLabel.text = [NSString stringWithFormat:@"%lu", [_contributions count]];
    
    if ([_contributions count] == 1) {
        _contributionTitleLabel.text = @"Contribution";
    }
    
    _contributionsLabel.adjustsFontSizeToFitWidth = YES;
    _valueLabel.text = [NSString stringWithFormat:@"$%lu", _totalValue];
    _valueLabel.adjustsFontSizeToFitWidth = YES;
    
    // _descriptionTextView.text = _task[@"description"];
    _descriptionTextView.text = @"Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.";
    
    __weak id weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        PFFile* file = _task[@"image"];
        
        if (file) {
            NSData* data = [file getData];
            if (data) {
                if (weakSelf) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _imageView.image = [UIImage imageWithData:[file getData]];
                    });
                }
            }
        }
    });
    
    _contributeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    _claimButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    if ([_task[@"claimed"] boolValue]) {
        [_claimButton setTitle:@"Claimed" forState:UIControlStateNormal];
        _claimButton.enabled = NO;
        [_claimButton setTitleColor:nil forState:UIControlStateNormal];
        _contributeButton.enabled = NO;
    }
    
    if (_hasContributed) {
        [_contributeButton setTitle:[NSString stringWithFormat:@"You've contributed $%ld", (long)_myContribution] forState:UIControlStateNormal];
    }
    
    if ([_task[@"poster"] isEqualToString:[PFUser currentUser].username]) {
        _claimButton.enabled = NO;
        [_claimButton setTitleColor:nil forState:UIControlStateNormal];
        [_claimButton setTitle:@"Can't claim your own task" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
