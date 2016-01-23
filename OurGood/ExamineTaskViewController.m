//
//  ExamineTaskViewController.m
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import "ExamineTaskViewController.h"

#define COLLECTION_VIEW_SPACING 8.f

#define CELL_SHADOW_VIEW_TAG 3
#define CELL_IMAGE_VIEW_TAG 2
#define CELL_LABEL_TAG 1

@interface ExamineTaskViewController ()

@property (nonatomic, strong) NSArray* contributors;

@end

@implementation ExamineTaskViewController

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(50.f, 75.f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return COLLECTION_VIEW_SPACING;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _contributors.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(COLLECTION_VIEW_SPACING / 2, COLLECTION_VIEW_SPACING / 2, COLLECTION_VIEW_SPACING / 2, COLLECTION_VIEW_SPACING / 2);
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* const Identifier = @"UserView";
    
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:Identifier forIndexPath:indexPath];
    cell.layer.masksToBounds = NO;
    
    UILabel* nameLabel = [cell viewWithTag:CELL_LABEL_TAG];
    UIImageView* profilePictureView = [cell viewWithTag:CELL_IMAGE_VIEW_TAG];
    UIView* shadowView = [cell viewWithTag:CELL_SHADOW_VIEW_TAG];
    
    assert([nameLabel isKindOfClass:[UILabel class]]);
    assert([profilePictureView isKindOfClass:[UIImageView class]]);
    assert([shadowView isKindOfClass:[UIView class]]);
    
    //cell.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255) / (CGFloat)255 green:arc4random_uniform(255) / (CGFloat)255 blue:arc4random_uniform(255) / (CGFloat)255 alpha:1.f];
    
    profilePictureView.layer.cornerRadius = profilePictureView.frame.size.width / 2.f;
    profilePictureView.layer.masksToBounds = YES;
    
    shadowView.layer.cornerRadius = profilePictureView.layer.cornerRadius;
    shadowView.layer.masksToBounds = NO;
    shadowView.layer.shadowOffset = CGSizeZero;
    shadowView.layer.shadowOpacity = 1.f;
    shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    shadowView.layer.shadowRadius = 1.f;
    shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:shadowView.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(profilePictureView.frame.size.width / 2.f, profilePictureView.frame.size.width / 2.f)].CGPath;
    
    PFUser* contributor = _contributors[indexPath.row];
    
    nameLabel.text = contributor[@"username"];
    if (contributor[@"image"]) {
        profilePictureView.image = contributor[@"image"];
    } else {
        profilePictureView.image = [UIImage imageNamed:@"default_user_image.png"];
    }
    
    return cell;
}

- (void)updateUI {
    _titleLabel.text = _task[@"title"];
    _descriptionTextView.text = @"Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.";
    
    if (_task[@"claimant"]) {
        _claimPeriodLabel.text = [NSString stringWithFormat:@"Claimed by %@", _task[@"claimant"]];
        
        _helpButton.enabled = NO;
        [_helpButton setTitle:@"Task Claimed" forState:UIControlStateNormal];
    } else {
        _claimPeriodLabel.text = [NSString stringWithFormat:@"%i day claim period", [_task[@"claimPeriod"] intValue]];
    }
    
    if ([[PFUser currentUser].objectId isEqualToString:[_task[@"poster"] objectId]]) {
        _posterLabel.text = @"You posted this task";
    } else {
        _posterLabel.text = [NSString stringWithFormat:@"%@ posted this task", _task[@"poster"]];
    }
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.doesRelativeDateFormatting = YES;
    
    _creationDateLabel.text = [NSString stringWithFormat:@"Posted %@", [formatter stringFromDate:_task.createdAt]];
    
    if ([_contributions count] == 1) {
        _contributionTitleLabel.text = @"Contribution";
    }
    
    if (_contributions) {
        _valueLabel.text = [NSString stringWithFormat:@"$%.02f", _totalValue];
        _yourContributionLabel.text = [NSString stringWithFormat:@"$%.02f", _myContribution];
        
        _contributionsLabel.text = [NSString stringWithFormat:@"%lu", [_contributions count]];
    }
    
    [_collectionView reloadData];
}

- (BOOL)hasBitcoinAddress {
    return [[PFUser currentUser][@"address"] length];
}

- (void)contributionsRetrieved:(NSArray * _Nullable)objects withError:(NSError * _Nullable)error {
    if (error) {
        NSLog(@"ERROR ACQUIRING CONTRIBUTIONS: %@", error.localizedDescription);
        return;
    }
    
    _totalValue = 0;
    _myContribution = 0;
    _contributions = objects;
    
    NSMutableArray* contributors = [[NSMutableArray alloc] init];
    
    for (PFObject* contribution in objects) {
        float amount = [contribution[@"amount"] floatValue];
        _totalValue += amount;
        
        if ([[contribution[@"contributor"] objectId] isEqualToString:[PFUser currentUser].objectId]) {
            _hasContributed = YES;
            _myContribution += amount;
        }
        
        if (![contributors containsObject:contribution[@"contributor"]]) {
            [contributors addObject:contribution[@"contributor"]];
        }
    }
    
    _contributors = contributors;
    
    [self updateUI];
}

- (void)updateContributions:(BOOL)async {
    PFQuery* query = [PFQuery queryWithClassName:@"Contribution"];
    [query whereKey:@"task" equalTo:_task];
    [query includeKey:@"contributor"];
    
    if (async) {
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            [self contributionsRetrieved:objects withError:error];
        }];
    } else {
        NSError* error = nil;
        NSArray* objects = [query findObjects:&error];
        [self contributionsRetrieved:objects withError:error];
    }
}

- (void)setTask:(PFObject *)task {
    _task = task;
    
    [self updateContributions:YES];
}

- (IBAction)helpButtonPressed:(id)sender {
    UIAlertController* controller = [UIAlertController alertControllerWithTitle:@"How would you like to help?" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [controller addAction:[UIAlertAction actionWithTitle:@"Claim this task" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self claimPressed:nil];
    }]];
    
    [controller addAction:[UIAlertAction actionWithTitle:@"Contribute to this task" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self contributePressed:nil];
    }]];
    
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)imageButtonPressed:(id)sender {
    // TODO - Go fullscreen
}

- (IBAction)claimPressed:(id)sender {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Are You Sure?" message:[NSString stringWithFormat:@"Are you sure you want to claim this task? You will have %i days to check in with the poster on your progress.", [_task[@"claimPeriod"] intValue]] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Claim" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        _task[@"claimDate"] = [NSDate date];
        _task[@"claimed"] = @YES;
        _task[@"claimant"] = [PFUser currentUser].username;
        
        [_task saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [self dismissViewControllerAnimated:YES completion:nil];
            
            if (error) {
                NSLog(@"ERROR SAVING TASK UPON CLAIMING: %@", error);
                return;
            }
            
            [self updateUI];
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
    UIAlertController* contributionAmountAlert = [UIAlertController alertControllerWithTitle:@"How much would you like to contribute?" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [contributionAmountAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.keyboardType = UIKeyboardTypeNumberPad;
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        textField.placeholder = @"Enter a dollar amount";
    }];
    
    UIAlertAction* action = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [contributionAmountAlert addAction:action];
    
    UIAlertAction* contributeAction = [UIAlertAction actionWithTitle:@"Contribute" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        float amount = [contributionAmountAlert.textFields[0].text floatValue];
        
        PFObject* newContribution = [PFObject objectWithClassName:@"Contribution"];
        newContribution[@"contributor"] = [PFUser currentUser];
        newContribution[@"task"] = _task;
        newContribution[@"amount"] = @(amount);
        
        UIAlertController* saving = [UIAlertController alertControllerWithTitle:@"Sending Your Contribution..." message:@"Please wait" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:saving animated:YES completion:^{
            [newContribution saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [self updateContributions:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [saving setTitle:@"Contribution Sent!"];
                        [saving setMessage:nil];
                        
                        _myContribution += amount;
                        _totalValue += amount;
                        
                        [self updateUI];
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                    });
                });
                
            }];
        }];
    }];
    
    _contributeAction = contributeAction;
    contributeAction.enabled = NO;
    [contributionAmountAlert addAction:contributeAction];
    [self presentViewController:contributionAmountAlert animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Task Info";
    
    [self updateUI];
    
    _helpButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    _helpButton.titleLabel.minimumScaleFactor = .2f;
    _helpButton.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    
    // Filler image
    _imageView.image = [UIImage imageNamed:@"Pothole.jpg"];
    _imageView.layer.cornerRadius = 2.f;
    
    __weak id weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        PFFile* file = _task[@"image"];
        
        if (file) {
            NSData* data = [file getData];
            if (data) {
                if (weakSelf) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //_imageView.image = [UIImage imageWithData:[file getData]];
                    });
                }
            }
        }
    });
    
    _imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    _imageView.layer.shadowOpacity = .5f;
    _imageView.layer.shadowOffset = CGSizeZero;
    _imageView.layer.shadowRadius = 1.f;
    
    _labelContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    _labelContainer.layer.shadowOpacity = .5f;
    _labelContainer.layer.shadowOffset = CGSizeZero;
    _labelContainer.layer.shadowRadius = 1.f;
    
    _collectionContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    _collectionContainer.layer.shadowOpacity = .5f;
    _collectionContainer.layer.shadowOffset = CGSizeZero;
    _collectionContainer.layer.shadowRadius = 1.f;
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
