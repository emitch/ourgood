//
//  ExamineTaskViewController.h
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ExamineTaskViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
    NSArray* _contributions;
    
    __weak UIAlertAction* _contributeAction;
    
    long _totalValue;
    long _myContribution;
    
    BOOL _hasContributed;
}

- (IBAction)claimPressed:(id)sender;
- (IBAction)contributePressed:(id)sender;

@property (nonatomic, weak) IBOutlet UIButton* helpButton;
@property (nonatomic, weak) IBOutlet UIButton* imageButton;

@property (nonatomic, weak) IBOutlet UIView* collectionContainer;
@property (nonatomic, weak) IBOutlet UIView* labelContainer;

@property (nonatomic, weak) IBOutlet UITextView* descriptionTextView;

@property (nonatomic, weak) IBOutlet UIImageView* imageView;

@property (nonatomic, weak) IBOutlet UICollectionView* collectionView;


@property (nonatomic, weak) IBOutlet UILabel* claimPeriodLabel;
@property (nonatomic, weak) IBOutlet UILabel* yourContributionLabel;
@property (nonatomic, weak) IBOutlet UILabel* contributionTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel* titleLabel;
@property (nonatomic, weak) IBOutlet UILabel* posterLabel;
@property (nonatomic, weak) IBOutlet UILabel* contributionsLabel;
@property (nonatomic, weak) IBOutlet UILabel* valueLabel;

@property (nonatomic, strong) PFObject* task;

@end
