//
//  ExamineTaskViewController.m
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import "ExamineTaskViewController.h"

@interface ExamineTaskViewController ()

@end

@implementation ExamineTaskViewController

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
            _hasContributed = YES;
            _myContribution = [payment[@"amount"] intValue];
        }
    }
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
    
    if ([[PFUser currentUser].username isEqualToString:_task[@"poster"]]) {
        _titleLabel.text = @"Posted by you!";
    } else {
        _titleLabel.text = [NSString stringWithFormat:@"Posted by: %@", _task[@"poster"]];
    }
    if ([_contributions count] == 1) {
        _contributionsLabel.text = @"1 Contribution";
    } else {
        _contributionsLabel.text = [NSString stringWithFormat:@"%lu Contributions", [_contributions count]];
    }
    _valueLabel.text = [NSString stringWithFormat:@"Worth $%lu.00", _totalValue];
    _descriptionTextView.text = _task[@"description"];
    
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
        _contributeButton.enabled = NO;
        [_contributeButton setTitle:[NSString stringWithFormat:@"You contributed $%ld", (long)_myContribution] forState:UIControlStateNormal];
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
