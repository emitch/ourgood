//
//  NewTaskViewController.m
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import "NewTaskViewController.h"
#import <Parse/Parse.h>
#import "LocationSingleton.h"

@interface NewTaskViewController ()

@property (nonatomic, strong) PFGeoPoint* point;

@end

@implementation NewTaskViewController

#define BC_TO_SATOSHI 100000000
#define BLOCKCHAIN_API_KEY @"74c72cf4-9042-4d46-8506-3ceac4f862f9"
#define APP_MONEY_BOX_ADDRESS @"1Ko9TMHvR8X9a7s8PxnpedYHDuvY8VRgC1"

- (float)BCtoUSD {
    NSString* conversionURLString = @"https://blockchain.info/ticker?api_code=$api_key";
    conversionURLString = [conversionURLString stringByReplacingOccurrencesOfString:@"$api_key" withString:BLOCKCHAIN_API_KEY];
    
    NSError* conversionError = nil;
    
    NSString* GETconversion = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:conversionURLString] encoding:NSUTF8StringEncoding error:&conversionError];
    
    NSDictionary* conversionDict = [NSJSONSerialization JSONObjectWithData:[GETconversion dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    
    float conversionRate = [conversionDict[@"USD"][@"last"] floatValue];
    
    NSLog(@"%@", GETconversion);
    
    return conversionRate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _point = [LocationSingleton sharedSingleton].geoPoint;
    
    UIView* contributionsPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, _titleField.frame.size.height)];
    contributionsPadding.backgroundColor = [UIColor colorWithWhite:.95f alpha:1.f];
    UIView* claimPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, _titleField.frame.size.height)];
    claimPadding.backgroundColor = [UIColor colorWithWhite:.95f alpha:1.f];
    
    _contributionField.leftView = contributionsPadding;
    _claimPeriodField.leftView = claimPadding;
    
    _titleField.leftViewMode = UITextFieldViewModeAlways;
    _contributionField.leftViewMode = UITextFieldViewModeAlways;
    _claimPeriodField.leftViewMode = UITextFieldViewModeAlways;
    _titleField.rightViewMode = UITextFieldViewModeAlways;
    _contributionField.rightViewMode = UITextFieldViewModeAlways;
    _claimPeriodField.rightViewMode = UITextFieldViewModeAlways;
    // Do any additional setup after loading the view.
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [textView selectAll:nil];
    });
}

- (IBAction)textFieldTyped:(UITextField *)sender {
    if ([_titleField.text length] && [_contributionField.text length] && [_claimPeriodField.text length] && [_descriptionView.text length]) {
        _submitButton.enabled = YES;
    } else {
        _submitButton.enabled = NO;
    }
}

- (IBAction)submitButtonPressed:(id)sender {
    PFObject* task = [PFObject objectWithClassName:@"Task"];
    task[@"title"] = _titleField.text;
    task[@"poster"] = [PFUser currentUser];
    task[@"claimPeriod"] = @([_claimPeriodField.text integerValue]);
    task[@"postLocation"] = _point;
    task[@"description"] = _descriptionView.text;
    task[@"community"] = _community;
    if (_imageView.image) {
        task[@"image"] = [PFFile fileWithData:UIImageJPEGRepresentation(_imageView.image, .3f)];
    }
    
    float contributionAmount = [_contributionField.text floatValue];
    PFObject* contribution = [PFObject objectWithClassName:@"Contribution"];
    contribution[@"contributor"] = [PFUser currentUser].username;
    contribution[@"amount"] = @(contributionAmount);
    contribution[@"task"] = task;
    
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Posting..." message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertController animated:YES completion:^{
        NSLog(@"saving new task");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError* saveError = nil;
            [task save:&saveError];
            if (saveError) {
                NSLog(@"ERROR SAVING TASK: %@", saveError.localizedDescription);
                return;
            }
            [contribution save:&saveError];
            if (saveError) {
                NSLog(@"ERROR SAVING CONTRIBUTION: %@", saveError.localizedDescription);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:^{
                    UIAlertController* success = [UIAlertController alertControllerWithTitle:@"Success!" message:@"Task posted; funds transferred." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self dismissViewControllerAnimated:YES completion:^{
                            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                        }];
                    }];
                    [success addAction:action];
                    
                    [self presentViewController:success animated:YES completion:nil];
                }];
            });
        });
    }];
}

- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIImage* image = info[UIImagePickerControllerOriginalImage];
    _imageView.image = image;
    _uploadImageButton.tintColor = [UIColor colorWithWhite:0.f alpha:.4f];
}

- (IBAction)cameraButtonPressed:(id)sender {
    UIImagePickerController* controller = [[UIImagePickerController alloc] init];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
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
