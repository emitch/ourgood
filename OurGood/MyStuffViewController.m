//
//  MyStuffViewController.m
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import "MyStuffViewController.h"

@interface MyStuffViewController ()

@end

@implementation MyStuffViewController

#define DAYS_TO_SECONDS         (24 * 60 * 60)
#define BLOCKCHAIN_API_KEY      @"74c72cf4-9042-4d46-8506-3ceac4f862f9"
#define SATOSHI_TO_BC           (1 / (float)100000000)

#define APP_MONEY_BOX_ADDRESS   @"1Ko9TMHvR8X9a7s8PxnpedYHDuvY8VRgC1"
#define APP_MONEY_BOX_GUID      @"78adc4eb-8f0b-4b7b-8b75-0bd5bba6375b"
#define APP_MONEY_BOX_PASSWORD  @"APP_MONEY_BOX"

#define FEE_SATOSHI 10000

typedef enum {
    TASKSPOSTED = 0,
    TASKSCLAIMED = 1
} TASKTYPE;

static NSString* const GetClaimedTasksForUser = @"getClaimedTasksForUser";
static NSString* const GetPostedTasksForUser = @"getPostedTasksForUser";

static NSString* const CreateBitcoinWallet = @"createBitcoinWallet";

static NSString* const CreateWalletUsername = @"username";
static NSString* const CreateWalletPassword = @"password";

static NSString* const UserIDParameterName = @"userId";

static NSString* const GUIDKey = @"guid";
static NSString* const AddressKey = @"address";

- (BOOL)hasBitcoinAddress {
    return [[PFUser currentUser][@"address"] length];
}

- (float)BCtoUSD {
    NSString* conversionURLString = @"https://blockchain.info/ticker?api_code=$api_key";
    conversionURLString = [conversionURLString stringByReplacingOccurrencesOfString:@"$api_key" withString:BLOCKCHAIN_API_KEY];
    
    NSError* conversionError = nil;
    
    NSString* GETconversion = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:conversionURLString] encoding:NSUTF8StringEncoding error:&conversionError];
    
    NSDictionary* conversionDict = [NSJSONSerialization JSONObjectWithData:[GETconversion dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    
    float conversionRate = [conversionDict[@"USD"][@"last"] floatValue];
    
    return conversionRate;
}

- (void)retrieveClaimedTasks:(BOOL)invalidate {
    if (invalidate) {
        //_claimed = nil;
    }
    
    NSDictionary* userTasksParameters = @{UserIDParameterName: [PFUser currentUser].username};
    
    [PFCloud callFunctionInBackground:GetClaimedTasksForUser
                       withParameters:userTasksParameters
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                    NSLog(@"Response for claimed tasks: %lu", [object count]);
                                    if (error) {
                                        NSLog(@"Error for claimed: %@", error);
                                    }
                                    
                                    _claimed = object;
                                    
                                    if (_tableViewControl.selectedSegmentIndex == TASKSCLAIMED) {
                                        [_tableView reloadData];
                                        [_refreshControl endRefreshing];
                                    }
                                }];
}

- (void)retreivePostedTasks:(BOOL)invalidate {
    if (invalidate) {
        //_claimed = nil;
    }
    
    NSDictionary* userTasksParameters = @{UserIDParameterName: [PFUser currentUser].username};
        
    [PFCloud callFunctionInBackground:GetPostedTasksForUser
                       withParameters:userTasksParameters
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                    NSLog(@"Response for posted tasks: %lu", [object count]);
                                    if (error) {
                                        NSLog(@"Error for posted: %@", error);
                                    }
                                    
                                    _posted = object;
                                    
                                    if (_tableViewControl.selectedSegmentIndex == TASKSPOSTED) {
                                        [_tableView reloadData];
                                        [_refreshControl endRefreshing];
                                    }
                                }];
}

- (void)refreshControlUsed:(id)sender {
    [self refresh:NO];
}

- (void)refresh:(BOOL)invalidate {
    if (invalidate) {
        _claimed = nil;
        _posted = nil;
        [_tableView reloadData];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self retrieveClaimedTasks:invalidate];
        [self retreivePostedTasks:invalidate];
        
        if (invalidate) {
            [_tableView reloadData];
        }
    });
}

- (void)textFieldUpdated {
    if (_bcController.textFields[0].text.length <= 10) {
        _bcAction.enabled = NO;
    } else {
        _bcAction.enabled = [_bcController.textFields[0].text isEqualToString:_bcController.textFields[1].text];
    }
}

- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:^{
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Success!" message:@"You're signed up and ready to go." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }];
}

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)logOut:(id)sender {
    _claimed = nil;
    _posted = nil;
    [_tableView reloadData];
    
    PFLogInViewController* logIn = [[PFLogInViewController alloc] init];
    logIn.delegate = self;
    
    PFSignUpViewController* signUp = [[PFSignUpViewController alloc] init];
    signUp.delegate = self;
    logIn.signUpController = signUp;
    
    [self presentViewController:logIn animated:NO completion:nil];
}

- (IBAction)bcAddressButtonPressed:(id)sender {
    if ([self hasBitcoinAddress]) {
        NSString* URLString = @"https://blockchain.info/merchant/$guid/balance?password=$main_password&api_code=$api_key";
        URLString = [URLString stringByReplacingOccurrencesOfString:@"$guid" withString:[PFUser currentUser][@"guid"]];
        URLString = [URLString stringByReplacingOccurrencesOfString:@"$main_password" withString:[PFUser currentUser][@"walletPassword"]];
        URLString = [URLString stringByReplacingOccurrencesOfString:@"$api_key" withString:BLOCKCHAIN_API_KEY];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError* error = nil;
            NSString* GETbalance = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:URLString] encoding:NSUTF8StringEncoding error:&error];
            NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:[GETbalance dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
            float conversionRate = [self BCtoUSD];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    float BC = ([dictionary[@"balance"] intValue] * SATOSHI_TO_BC);
                    NSLog(@"%@", URLString);
                    
                    UIAlertController* controller = [UIAlertController alertControllerWithTitle:@"Wallet Status" message:[NSString stringWithFormat:@"Address:\n%@\nBalance:\n$%.2f (฿%.4f)", [PFUser currentUser][@"address"], BC * conversionRate, BC] preferredStyle:UIAlertControllerStyleAlert];
                    
                    [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        
                    }]];
                    
                    [self presentViewController:controller animated:YES completion:nil];
                }
            });
        });
    } else {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Enter a Password:" message:@"This is the password you will use to access your Bitcoin Wallet. It must be at least 10 characters long. If you lose it, you will lose access to your wallet!" preferredStyle:UIAlertControllerStyleAlert];
        _bcController = alertController;
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.secureTextEntry = YES;
            textField.placeholder = @"Password";
            [textField addTarget:self action:@selector(textFieldUpdated) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.secureTextEntry = YES;
            textField.placeholder = @"Confirm Password";
            [textField addTarget:self action:@selector(textFieldUpdated) forControlEvents:UIControlEventEditingChanged];
        }];
        
        UIAlertAction* action = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [PFUser currentUser][@"walletPassword"] = alertController.textFields[0].text;
            NSString* URLBaseString = @"https://blockchain.info/api/v2/create_wallet";
            URLBaseString = [URLBaseString stringByAppendingFormat:@"?password=%@", alertController.textFields[0].text];
            URLBaseString = [URLBaseString stringByAppendingFormat:@"&api_code=%@", BLOCKCHAIN_API_KEY];
            
            NSDictionary* parameters = @{CreateWalletUsername: [PFUser currentUser].username,
                                         CreateWalletPassword: alertController.textFields[0].text};
            
            [PFCloud callFunctionInBackground:CreateBitcoinWallet
                               withParameters:parameters
                                        block:^(id  _Nullable object, NSError * _Nullable error) {
                                            NSLog(@"%@", object);
                                            NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[((NSString*)object) dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
                                            //NSLog(@"%@", response);
                                            if (response[GUIDKey] && response[AddressKey]) {
                                                [PFUser currentUser][GUIDKey] = response[GUIDKey];
                                                [PFUser currentUser][AddressKey] = response[AddressKey];
                                                
                                                [_bcAddressButton setTitle:@"Payment linked \u2713" forState:UIControlStateNormal];
                                            }
                                            
                                            
                                            if (error) {
                                                NSLog(@"ERROR CREATING WALLET: %@", error);
                                            }
                                        }];
        }];
        [alertController addAction:action];
        action.enabled = NO;
        _bcAction = action;
        
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancel];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
    }
}

- (IBAction)passwordButtonPressed:(id)sender {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Enter New Password:" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction* action = [UIAlertAction actionWithTitle:@"Change" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [PFUser currentUser].password = alertController.textFields[0].text;
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            UIAlertController* success = [UIAlertController alertControllerWithTitle:@"Success!" message:@"Password changed." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [success addAction:action];
            
            [self presentViewController:success animated:YES completion:nil];
        }];
    }];
    [alertController addAction:action];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_tableView reloadData];
    
    _usernameLabel.text = [PFUser currentUser].username;
    
    [self refresh:![[PFUser currentUser].username isEqualToString:_lastUsername]];
    
    if ([self hasBitcoinAddress]) {
        [_bcAddressButton setTitle:@"Payment linked \u2713" forState:UIControlStateNormal];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _lastUsername = [[PFUser currentUser].username copy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageView.layer.masksToBounds = NO;
    _imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    _imageView.layer.shadowOpacity = .5f;
    _imageView.layer.shadowOffset = CGSizeZero;
    _imageView.layer.shadowRadius = 1.f;
    _imageView.layer.cornerRadius = 2.f;
    
    _tableView.layer.masksToBounds = NO;
    _tableView.layer.shadowColor = [UIColor blackColor].CGColor;
    _tableView.layer.shadowOpacity = .5f;
    _tableView.layer.shadowOffset = CGSizeZero;
    _tableView.layer.shadowRadius = 1.f;
    
    _usernameLabel.adjustsFontSizeToFitWidth = YES;
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.doesRelativeDateFormatting = YES;
    [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlUsed:) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:refreshControl];
    _refreshControl = refreshControl;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_tableViewControl.selectedSegmentIndex == TASKSPOSTED) {
        PFObject* task = _posted[indexPath.row];
        
        if ([_posted[indexPath.row][@"claimed"] boolValue]) {
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Release Funds?" message:[NSString stringWithFormat:@"Has this task been completed? If so, we can release the funds to the claimee, %@", _posted[indexPath.row][@"claimee"]] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Release" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self dismissViewControllerAnimated:YES completion:nil];
                UIAlertController* loading = [UIAlertController alertControllerWithTitle:@"Releasing..." message:@"" preferredStyle:UIAlertControllerStyleAlert];
                [self presentViewController:loading animated:YES completion:^{
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        [task delete];
                        
                        PFQuery *query = [PFUser query];
                        [query whereKey:@"username" equalTo:task[@"claimee"]];
                        PFUser *claimee = (PFUser *)[query getFirstObject];
                        
                        int total = 0;
                        for (PFObject* payment in task[@"committedPayments"]) {
                            [payment fetchIfNeeded];
                            total += [payment[@"amount"] intValue];
                        }
                        
//                        NSString* transferURLString = @"https://blockchain.info/merchant/$guid/payment?password=$main_password&to=$address&amount=$amount&from=$from&api_key=$api_key";
//                        transferURLString = [transferURLString stringByReplacingOccurrencesOfString:@"$from" withString:APP_MONEY_BOX_ADDRESS];
//                        transferURLString = [transferURLString stringByReplacingOccurrencesOfString:@"$amount" withString:[NSString stringWithFormat:@"%i", (int)((total / [self BCtoUSD]) / SATOSHI_TO_BC) - FEE_SATOSHI]];
//                        transferURLString = [transferURLString stringByReplacingOccurrencesOfString:@"$address" withString:claimee[@"address"]];
//                        transferURLString = [transferURLString stringByReplacingOccurrencesOfString:@"$main_password" withString:APP_MONEY_BOX_PASSWORD];
//                        transferURLString = [transferURLString stringByReplacingOccurrencesOfString:@"$guid" withString:APP_MONEY_BOX_GUID];
//                        transferURLString = [transferURLString stringByReplacingOccurrencesOfString:@"$api_key" withString:BLOCKCHAIN_API_KEY];
//                        
//                        NSString* transferResponse = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:transferURLString] encoding:NSUTF8StringEncoding error:nil];
//                        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:[transferResponse dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
//                        if (dict[@"tx_hash"]) {
                            // successful transfer
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self dismissViewControllerAnimated:YES completion:^{
                                    UIAlertController* success = [UIAlertController alertControllerWithTitle:@"Success!" message:@"Funds transferred." preferredStyle:UIAlertControllerStyleAlert];
                                    UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                                    [success addAction:action];
                                    
                                    [self presentViewController:success animated:YES completion:nil];
                                }];
                            });
//                        } else {
//                            [task save];
//                            dispatch_async(dispatch_get_main_queue(), ^{
//                                [self dismissViewControllerAnimated:YES completion:^{
//                                    UIAlertController* error = [UIAlertController alertControllerWithTitle:@"Error Transferring Funds" message:transferResponse preferredStyle:UIAlertControllerStyleAlert];
//                                    UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
//                                    [error addAction:action];
//                                    
//                                    [self presentViewController:error animated:YES completion:nil];
//                                }];
//                            });
//                        }
                    });
                }];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }]];
            
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            UIAlertController* error = [UIAlertController alertControllerWithTitle:@"Task Still Unclaimed" message:@"This task still hasn't been claimed by anyone. Be patient!" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [error addAction:action];
            
            [self presentViewController:error animated:YES completion:nil];
        }
    } else {
        UIAlertController* info = [UIAlertController alertControllerWithTitle:@"TODO" message:[NSString stringWithFormat:@"Task Description:\n%@", _claimed[indexPath.row][@"description"]] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [info addAction:action];
        
        [self presentViewController:info animated:YES completion:nil];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* ClaimedID = @"ClaimedTaskCellID";
    static NSString* PostedID = @"PostedTaskCellID";
    
    NSString* identifier = _tableViewControl.selectedSegmentIndex == TASKSPOSTED ? PostedID : ClaimedID;
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    
    if (_tableViewControl.selectedSegmentIndex == TASKSPOSTED) {
        if (_posted) {
            cell.textLabel.text = [_posted[indexPath.row] objectForKey:@"title"];
            cell.detailTextLabel.text = [_posted[indexPath.row] objectForKey:@"description"];
        } else {
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"";
        }
    } else {
        if (_claimed) {
            PFObject* task = _claimed[indexPath.row];
            NSInteger claimPeriod = [task[@"claimPeriod"] integerValue];
            NSDate* dueDate = [task[@"claimDate"] dateByAddingTimeInterval:claimPeriod * DAYS_TO_SECONDS];
            
            cell.textLabel.text = task[@"title"];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Due: %@", [_dateFormatter stringFromDate:dueDate]];
        } else {
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"";
        }
    }
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_tableViewControl.selectedSegmentIndex == TASKSPOSTED) {
        if (_posted.count) {
            return [NSString stringWithFormat:@"My Posted Tasks (%lu)", (unsigned long)_posted.count];
        } else if (_posted) {
            return @"No Posted Tasks";
        } else {
            return @"Loading...";
        }
    } else { /* _tableViewControl.selectedSegmentIndex == TASKSCLAIMED */
        if (_claimed.count) {
            return [NSString stringWithFormat:@"My Claimed Tasks (%lu)", (unsigned long)_claimed.count];
        } else if (_claimed) {
            return @"No Claimed Tasks";
        } else {
            return @"Loading...";
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_tableViewControl.selectedSegmentIndex == TASKSPOSTED) {
        return _posted ? _posted.count : 1;
    } else { /* _tableViewControl.selectedSegmentIndex == TASKSCLAIMED */
        return _claimed ? _claimed.count : 1;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (IBAction)segmentedControlChanged:(id)sender {
    [_tableView reloadData];
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
