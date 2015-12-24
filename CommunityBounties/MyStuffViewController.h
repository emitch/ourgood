//
//  MyStuffViewController.h
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface MyStuffViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate> {
    NSArray<PFObject*>* _claimed;
    NSArray<PFObject*>* _posted;
    
    __weak UIRefreshControl* _refreshControl;
    
    NSDateFormatter* _dateFormatter;
    
    NSString* _lastUsername;
    
    __weak UIAlertAction* _bcAction;
    __weak UIAlertController* _bcController;
}

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* indicator;
@property (nonatomic, weak) IBOutlet UIButton* bcAddressButton;
@property (nonatomic, weak) IBOutlet UIButton* passwordButton;
@property (nonatomic, weak) IBOutlet UILabel* usernameLabel;
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet UISegmentedControl* tableViewControl;

- (IBAction)logOut:(id)sender;
- (IBAction)bcAddressButtonPressed:(id)sender;
- (IBAction)passwordButtonPressed:(id)sender;
- (IBAction)segmentedControlChanged:(id)sender;

@end
