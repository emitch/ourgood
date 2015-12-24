//
//  HomeViewController.m
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import "HomeViewController.h"
#import <Parse/Parse.h>
#import "LocationSingleton.h"
#import "LocationAnnotation.h"
#import "NewTaskViewController.h"
#import "ExamineTaskViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

#define BLOCKCHAIN_API_KEY @"3f0ec865-2d01-426d-8d6b-44aa86b02f62"

static NSString* const GetLocalTasksFunction = @"getLocalTasks";
static NSString* const LocalTasksParameterName = @"postLocation";

- (BOOL)hasBitcoinAddress {
    return [[PFUser currentUser][@"address"] length];
}

- (void)updateMap {
    [_mapView removeAnnotations:_mapView.annotations];
    
    for (PFObject* object in _tasks) {
        LocationAnnotation* ann = [[LocationAnnotation alloc] init];
        ann.task = object;
        
        PFGeoPoint* point = object[@"postLocation"];
        ann.coordinate = CLLocationCoordinate2DMake(point.latitude, point.longitude);
        
        [_mapView addAnnotation:ann];
    }
    
    [_mapView showAnnotations:_mapView.annotations animated:YES];
}

- (void)retrieveLocalTasks {
    if (![[LocationSingleton sharedSingleton] geoPoint]) {
        UIAlertController* locationAlert = [UIAlertController alertControllerWithTitle:@"Couldn't Get Location" message:@"We're still trying to get your location. Try again in a few seconds." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [locationAlert addAction:cancel];
        
        [self presentViewController:locationAlert animated:YES completion:nil];
        [_refreshControl endRefreshing];
        return;
    }
    
    NSDictionary* userTasksParameters = @{LocalTasksParameterName: [[LocationSingleton sharedSingleton] geoPoint]};
    
    [PFCloud callFunctionInBackground:GetLocalTasksFunction
                       withParameters:userTasksParameters
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                    if (error) {
                                        NSLog(@"Error for posted: %@", error);
                                    }
                                    
                                    _tasks = object;
                                    
                                    [self updateMap];
                                    [_tableView reloadData];
                                    [_refreshControl endRefreshing];
                                }];
}

- (void)refresh:(BOOL)invalidate {
    if (invalidate) {
        _tasks = nil;
        [_tableView reloadData];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self retrieveLocalTasks];
    });
}

- (void)refreshControlUsed:(id)sender {
    [self refresh:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    if ([PFUser currentUser]) {
        [PFUser logOut];
    }
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlUsed:) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:refreshControl];
    _refreshControl = refreshControl;
}

- (void)newTaskPressed:(id)sender {
    if ([self hasBitcoinAddress]) {
        if ([LocationSingleton sharedSingleton].geoPoint) {
            UINavigationController* VC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NewTaskViewController"];
            [self presentViewController:VC animated:YES completion:nil];
        } else {
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Couldn't Determine Location" message:@"We can't post a task without your location. Wait a few seconds and try again." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:cancelAction];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }
    } else {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"No Bitcoin Address" message:@"You must add or create a Bitcoin address in My Stuff before posting a new task." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
}

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (annotation == mapView.userLocation) {
        return nil;
    }
    
    MKPinAnnotationView* view = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"ID"];
    if (!view) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ID"];
    }
    
    view.canShowCallout = YES;
    
    return view;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_tasks.count) {
        return [NSString stringWithFormat:@"Local Tasks (%lu)", (unsigned long)_tasks.count];
    } else if (_tasks) {
        return @"No Local Tasks - Make Your Own!";
    } else {
        return @"Loading...";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ExamineTaskViewController* VC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ExamineTaskViewController"];
    VC.task = _tasks[indexPath.row];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    [self.navigationController pushViewController:VC animated:YES];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* Identifier = @"CellID";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:Identifier];
    }
    
    if (_tasks) {
        PFObject* task = _tasks[indexPath.row];
        PFGeoPoint* geoPoint = task[@"postLocation"];
        CLLocation* location = [[CLLocation alloc] initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude];
        
        cell.textLabel.text = task[@"title"];
        cell.detailTextLabel.text = [[LocationSingleton sharedSingleton] distanceTo:location];
        
        if ([task[@"poster"] isEqualToString:[PFUser currentUser].username]) {
            cell.contentView.backgroundColor = [UIColor colorWithWhite:.9f alpha:1.f];
        } else {
            cell.contentView.backgroundColor = [UIColor whiteColor];
        }
        
        cell.userInteractionEnabled = YES;
    } else {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
        cell.userInteractionEnabled = NO;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tasks ? _tasks.count : 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _lastUsername = [[PFUser currentUser].username copy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![PFUser currentUser]) {
        PFLogInViewController* logIn = [[PFLogInViewController alloc] init];
        logIn.delegate = self;
        
        PFSignUpViewController* signUp = [[PFSignUpViewController alloc] init];
        signUp.delegate = self;
        logIn.signUpController = signUp;
        
        [self presentViewController:logIn animated:NO completion:nil];
    } else {
        [self refresh:![[PFUser currentUser].username isEqualToString:_lastUsername]];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
