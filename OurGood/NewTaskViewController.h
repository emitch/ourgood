//
//  NewTaskViewController.h
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFGeoPoint;

@interface NewTaskViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate> {
    PFGeoPoint* _point;
}

@property (nonatomic, weak) IBOutlet UITextView* descriptionView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* submitButton;
@property (nonatomic, weak) IBOutlet UIButton* uploadImageButton;
@property (nonatomic, weak) IBOutlet UIImageView* imageView;
@property (nonatomic, weak) IBOutlet UITextField* titleField;
@property (nonatomic, weak) IBOutlet UITextField* contributionField;
@property (nonatomic, weak) IBOutlet UITextField* claimPeriodField;

- (IBAction)textFieldTyped:(UITextField*)sender;
- (IBAction)cameraButtonPressed:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)submitButtonPressed:(id)sender;

@end
