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
#import "AppDelegate.h"
#import "PagingCollectionViewLayout.h"

@interface HomeViewController ()

@property (nonatomic) NSInteger selectedCommunity;

@end

@implementation HomeViewController

#define BLOCKCHAIN_API_KEY      @"3f0ec865-2d01-426d-8d6b-44aa86b02f62"

#define COLLECTION_VIEW_SPACING 8.f

#define CELL_TITLE_LABEL_TAG    1
#define CELL_DETAIL_VIEW_TAG    2
#define CELL_BUTTON_TAG         3

static NSString* const GetLocalTasksFunction = @"getLocalTasks";
static NSString* const LocalTasksParameterName = @"postLocation";

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* const Identifier = @"CommunityCell";
    
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:Identifier forIndexPath:indexPath];
    
    UILabel* titleLabel = [cell viewWithTag:CELL_TITLE_LABEL_TAG];
    UITextView* detailView = [cell viewWithTag:CELL_DETAIL_VIEW_TAG];
    
    assert([titleLabel isKindOfClass:[UILabel class]]);
    assert([detailView isKindOfClass:[UITextView class]]);
    
    cell.layer.masksToBounds = NO;
    cell.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.layer.shadowOpacity = .5f;
    cell.layer.shadowOffset = CGSizeZero;
    cell.layer.shadowRadius = 1.f;
    cell.layer.cornerRadius = 2.f;
    
    if (indexPath.row == _selectedCommunity) {
        cell.layer.shadowColor = [cell viewWithTag:CELL_BUTTON_TAG].tintColor.CGColor;
        cell.layer.shadowRadius = 2.f;
        cell.layer.shadowOpacity = 1.f;
    }
    
    titleLabel.text = @"Some Community";
    detailView.text = @"Some information about this community.";
    
    return cell;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return CGSizeMake(150.f, 75.f);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(COLLECTION_VIEW_SPACING, COLLECTION_VIEW_SPACING, COLLECTION_VIEW_SPACING, COLLECTION_VIEW_SPACING);
}

- (IBAction)cellTapped:(UIButton*)sender {
    UICollectionViewCell* cell = (UICollectionViewCell*)sender.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]) {
        cell = (UICollectionViewCell*)cell.superview;
    }
    
    assert(cell != nil);
    assert([cell isKindOfClass:[UICollectionViewCell class]]);
    
    [self updateSelectedCommunity:[_collectionView indexPathForCell:cell].row];
}

- (void)updateSelectedCommunity:(NSInteger)selectedCommunity {
    _selectedCommunity = selectedCommunity;
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:selectedCommunity inSection:0];
    
    CGFloat offset = [self collectionView:_collectionView layout:_collectionView.collectionViewLayout insetForSectionAtIndex:0].left + ([self collectionView:_collectionView layout:_collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath].width + COLLECTION_VIEW_SPACING) * selectedCommunity - [self collectionView:_collectionView layout:_collectionView.collectionViewLayout minimumLineSpacingForSectionAtIndex:0];
    
    UICollectionViewCell* cell = [_collectionView cellForItemAtIndexPath:indexPath];
    
    self.navigationItem.title = ((UILabel*)[cell viewWithTag:CELL_TITLE_LABEL_TAG]).text;
    
    [_collectionView setContentOffset:CGPointMake(offset, 0) animated:YES];
    
    [_collectionView reloadData];
}

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
                                    [self updateSelectedCommunity:_selectedCommunity];
                                }];
}

- (void)refresh {
    if (![[PFUser currentUser].username isEqualToString:_lastUsername]) {
        _tasks = nil;
        [_tableView reloadData];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self retrieveLocalTasks];
    });
}

- (void)refreshControlUsed:(id)sender {
    [self refresh];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateSelectedCommunity:0];
    
    self.navigationItem.title = @"Loading...";
    
    _tableView.layer.masksToBounds = NO;
    _tableView.layer.shadowColor = [UIColor blackColor].CGColor;
    _tableView.layer.shadowOpacity = .5f;
    _tableView.layer.shadowOffset = CGSizeZero;
    _tableView.layer.shadowRadius = 1.f;
    
    _mapView.layer.masksToBounds = NO;
    _mapView.layer.shadowColor = [UIColor blackColor].CGColor;
    _mapView.layer.shadowOpacity = .5f;
    _mapView.layer.shadowOffset = CGSizeZero;
    _mapView.layer.shadowRadius = 1.f;

    _collectionView.collectionViewLayout = [[PagingCollectionViewLayout alloc] init];
    ((PagingCollectionViewLayout*)_collectionView.collectionViewLayout).scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView.decelerationRate = .1f;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlUsed:) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:refreshControl];
    _refreshControl = refreshControl;
    
    if (![PFUser currentUser]) {
        PFLogInViewController* logIn = [[PFLogInViewController alloc] init];
        logIn.delegate = self;
        
        PFSignUpViewController* signUp = [[PFSignUpViewController alloc] init];
        signUp.delegate = self;
        logIn.signUpController = signUp;
        
        [self presentViewController:logIn animated:NO completion:nil];
    } else {
        [self refresh];
    }
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
        return [NSString stringWithFormat:@"%lu Tasks", (unsigned long)_tasks.count];
    } else if (_tasks) {
        return @"No Local Tasks - Make Your Own!";
    } else {
        return @"Loading...";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ExamineTaskViewController* VC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ExamineTaskViewController"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        VC.task = _tasks[indexPath.row];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
            
            [self.navigationController pushViewController:VC animated:YES];
        });
    });
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* Identifier = @"CellID";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:Identifier];
    }
    
    if (_tasks.count) {
        PFObject* task = _tasks[indexPath.row];
        PFGeoPoint* geoPoint = task[@"postLocation"];
        CLLocation* location = [[CLLocation alloc] initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude];
        
        cell.textLabel.text = task[@"title"];
        cell.detailTextLabel.text = [[LocationSingleton sharedSingleton] distanceTo:location];
        
        if ([task[@"poster"] isEqualToString:[PFUser currentUser].username]) {
            cell.imageView.image = [UIImage imageNamed:@"Star"];
        } else {
            cell.imageView.image = nil;
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
    return _tasks.count ? _tasks.count : 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _lastUsername = [[PFUser currentUser].username copy];
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
