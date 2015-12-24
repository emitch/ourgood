//
//  HomeViewController.h
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <MapKit/MapKit.h>

@interface HomeViewController : UIViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate> {
    __weak UIRefreshControl* _refreshControl;
    
    NSArray<PFObject*>* _tasks;
    
    NSString* _lastUsername;
}

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* indicator;
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet MKMapView* mapView;

- (IBAction)newTaskPressed:(id)sender;

@end

