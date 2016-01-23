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
@property (nonatomic, strong) NSArray* communities;
@property (nonatomic, strong) NSArray* downloadedCommunities;
@property (nonatomic, strong) NSDictionary* tasks;
@property (nonatomic, strong) NSMutableDictionary* downloadedTasks;

@end

@implementation HomeViewController

#define BLOCKCHAIN_API_KEY      @"3f0ec865-2d01-426d-8d6b-44aa86b02f62"

#define COLLECTION_VIEW_SPACING 8.f

#define CELL_VIEW_TAG           4
#define CELL_TITLE_LABEL_TAG    1
#define CELL_BUTTON_TAG         3

static NSString* const GetLocalTasksFunction = @"getLocalTasks";
static NSString* const LocalTasksParameterName = @"postLocation";

- (UIColor*)colorForCommunity:(PFObject*)community {
    assert(community != nil);
    
    static const NSInteger NumColors = 20;
    static const CGFloat WheelSize = 360.f;
    static NSMutableArray* colors = nil;
    
    if (!colors) {
        colors = [[NSMutableArray alloc] init];
        
        for (int idx = 0; idx < WheelSize; idx += WheelSize / NumColors) {
            UIColor* color = [UIColor colorWithHue:idx / WheelSize saturation:1.f brightness:1.f alpha:1.f];
            [colors addObject:color];
        }
    }
    
    NSInteger index = [_communities indexOfObject:community];
    
    assert(index >= 0);
    
    return colors[index % NumColors];
}

- (NSArray*)tasksForCommunity:(PFObject*)community {
    assert(community != nil);
    
    if (_tasks == nil) return nil;
    
    return _tasks[community.objectId];
}

- (NSArray*)tasksForCurrentCommunity {
    if (!_communities.count) return nil;
    
    assert(_selectedCommunity >= 0);
    assert(_selectedCommunity < _communities.count);
    
    return [self tasksForCommunity:_communities[_selectedCommunity]];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    assert(indexPath.row <= [_communities count]);
    
    static NSString* const Identifier = @"SimpleCell";
    
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:Identifier forIndexPath:indexPath];
    
    UILabel* titleLabel = [cell viewWithTag:CELL_TITLE_LABEL_TAG];
    UIView* backgroundView = [cell viewWithTag:CELL_VIEW_TAG];
    
    assert([titleLabel isKindOfClass:[UILabel class]]);
    assert([backgroundView isKindOfClass:[UIView class]]);
    
    cell.layer.masksToBounds = NO;
    cell.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.layer.shadowOpacity = .65f;
    cell.layer.shadowOffset = CGSizeZero;
    cell.layer.shadowRadius = 1.f;
    cell.layer.cornerRadius = 1.f;
    
    backgroundView.layer.cornerRadius = cell.layer.cornerRadius;
    backgroundView.backgroundColor = [UIColor colorWithWhite:.95 alpha:1.f];
    titleLabel.textColor = [UIColor blackColor];
    
    if (indexPath.row < [_communities count]) {
        if (indexPath.row == _selectedCommunity) {
            cell.layer.shadowColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor;
            cell.layer.shadowRadius = 2.f;
            cell.layer.shadowOpacity = 1.f;
        }
        
        titleLabel.text = _communities[indexPath.row][@"name"];
    } else {
        titleLabel.text = @"Add Community";
        
        backgroundView.backgroundColor = [UIColor colorWithWhite:.0f alpha:1.f];
        titleLabel.textColor = [UIColor colorWithWhite:.95f alpha:1.f];
    }
    
    
    return cell;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return COLLECTION_VIEW_SPACING;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _communities ? _communities.count + 1 : 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return CGSizeMake(150.f, 30.f);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(COLLECTION_VIEW_SPACING, COLLECTION_VIEW_SPACING, COLLECTION_VIEW_SPACING, COLLECTION_VIEW_SPACING);
}

- (void)textFieldChanged:(UITextField*)sender {
    UIResponder* responder = sender;
    while (![responder isKindOfClass:[UIAlertController class]]) {
        responder = [responder nextResponder];
    }
    
    assert(responder != nil);
    
    UIAlertController* alert = (UIAlertController*)responder;
    alert.actions[1].enabled = sender.text.length != 0;
}

- (IBAction)cellTapped:(UIButton*)sender {
    UICollectionViewCell* cell = (UICollectionViewCell*)sender.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]) {
        cell = (UICollectionViewCell*)cell.superview;
    }
    
    assert(cell != nil);
    assert([cell isKindOfClass:[UICollectionViewCell class]]);
    
    NSInteger index = [_collectionView indexPathForCell:cell].row;
    
    if (index < [_communities count]) {
        [self updateSelectedCommunity:index];
    } else {
        UIAlertController* newCommunityAlert = [UIAlertController alertControllerWithTitle:@"New Community" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [newCommunityAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"New Community Name";
            [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [newCommunityAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction* addAction = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            PFObject* newCommunity = [PFObject objectWithClassName:@"Community"];
            newCommunity[@"creator"] = [PFUser currentUser];
            newCommunity[@"name"] = newCommunityAlert.textFields[0].text;
            
            UIAlertController* saving = [UIAlertController alertControllerWithTitle:@"Creating New Community..." message:nil preferredStyle:UIAlertControllerStyleAlert];
            [self presentViewController:saving animated:YES completion:nil];
            
            [newCommunity saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                [self dismissViewControllerAnimated:YES completion:nil];
                if (error) {
                    NSLog(@"ERROR SAVING NEW COMMUNITY: %@", error.localizedDescription);
                    UIAlertController* success = [UIAlertController alertControllerWithTitle:@"Error Creating Community" message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
                    [success addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
                    
                    return;
                }
                
                [[[PFUser currentUser] relationForKey:@"communities"] addObject:newCommunity];
                [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"ERROR SAVING NEW COMMUNITY: %@", error.localizedDescription);
                        UIAlertController* success = [UIAlertController alertControllerWithTitle:@"Error Creating Community" message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
                        [success addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
                        
                        return;
                    }
                    
                    _communities = [_communities arrayByAddingObject:newCommunity];
                    
                    NSMutableDictionary* newTasks = [NSMutableDictionary dictionaryWithDictionary:_tasks];
                    newTasks[newCommunity.objectId] = @[];
                    _tasks = newTasks;
                    
                    [self updateSelectedCommunity:[_communities count] - 1];
                    
                    UIAlertController* success = [UIAlertController alertControllerWithTitle:@"Community Created!" message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [success addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
                }];
            }];
        }];
        
        addAction.enabled = NO;
        
        [newCommunityAlert addAction:addAction];
        
        [self presentViewController:newCommunityAlert animated:YES completion:nil];
    }
}

- (void)updateSelectedCommunity:(NSInteger)selectedCommunity {
    if (!_communities.count) {
        if (_communities) {
            self.navigationItem.title = @"No Communities - Add One!";
        }
        
        [_collectionView reloadData];
        [_tableView reloadData];
        
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        return;
    }
    
    assert(_selectedCommunity < _communities.count);
    
    _selectedCommunity = selectedCommunity;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:selectedCommunity inSection:0];
    
    UICollectionViewCell* cell = [_collectionView cellForItemAtIndexPath:indexPath];
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@", _communities[_selectedCommunity][@"name"]];
    
    [_collectionView reloadData];
    [_tableView reloadData];
    
    if (CGRectContainsRect(self.view.frame, [self.view convertRect:cell.frame fromCoordinateSpace:cell.superview])) {
        return;
    }
    
    CGFloat offset = [self collectionView:_collectionView layout:_collectionView.collectionViewLayout insetForSectionAtIndex:0].left + ([self collectionView:_collectionView layout:_collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath].width + COLLECTION_VIEW_SPACING) * (selectedCommunity / 2) - [self collectionView:_collectionView layout:_collectionView.collectionViewLayout minimumLineSpacingForSectionAtIndex:0];
    
    [_collectionView setContentOffset:CGPointMake(offset, 0) animated:YES];
}

- (BOOL)hasBitcoinAddress {
    return [[PFUser currentUser][@"address"] length];
}

- (void)reloadUI {
    [self updateSelectedCommunity:_selectedCommunity];
    
    [self updateMap];
    
    if (_communities) {
        [_indicator stopAnimating];
        
        [_refreshControl endRefreshing];
        
        if (!_refreshControl) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshControlUsed:) forControlEvents:UIControlEventValueChanged];
        [_tableView addSubview:refreshControl];
        [_tableView sendSubviewToBack:refreshControl];
        _refreshControl = refreshControl;
        }
    }
}

- (void)updateMap {
    [_mapView removeAnnotations:_mapView.annotations];
    
    NSMutableArray* allTasks = [[NSMutableArray alloc] init];
    
    for (NSArray* tasks in [_tasks allValues]) {
        [allTasks addObjectsFromArray:tasks];
    }
    
    for (PFObject* object in allTasks) {
        LocationAnnotation* ann = [[LocationAnnotation alloc] init];
        ann.task = object;
        
        PFGeoPoint* point = object[@"postLocation"];
        ann.coordinate = CLLocationCoordinate2DMake(point.latitude, point.longitude);
        
        [_mapView addAnnotation:ann];
    }
    
    [_mapView showAnnotations:_mapView.annotations animated:YES];
}

- (void)retrieveTasks {
    PFRelation* communitiesRelation = [[PFUser currentUser] relationForKey:@"communities"];
    PFQuery* communitiesQuery = [communitiesRelation query];
    
    [communitiesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR RETRIEVING USER'S COMMUNITIES: %@", error.localizedDescription);
            return;
        }
        
        _downloadedCommunities = objects;
        _downloadedTasks = [[NSMutableDictionary alloc] init];
        
        for (PFObject* community in _downloadedCommunities) {
            PFQuery* taskQuery = [PFQuery queryWithClassName:@"Task"];
            [taskQuery whereKey:@"community" equalTo:community];
            
            [taskQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable tasks, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"ERROR RETRIEVING COMMUNITY %@'S TASKS: %@", community[@"name"], error.localizedDescription);
                    return;
                }
                
                _downloadedTasks[community.objectId] = tasks;
                
                if ([[_downloadedTasks allKeys] count] == [_downloadedCommunities count]) {
                    _communities = _downloadedCommunities;
                    _tasks = _downloadedTasks;
                    
                    _downloadedTasks = nil;
                    _downloadedCommunities = nil;
                    
                    [self reloadUI];
                }
            }];
        }
        
        if (![_downloadedCommunities count]) {
            _communities = _downloadedCommunities;
            _tasks = _downloadedTasks;
            [self reloadUI];
        }
    }];
}

- (void)refresh {
    if (![[PFUser currentUser].username isEqualToString:_lastUsername]) {
        _tasks = nil;
        _communities = nil;
        
        self.navigationItem.title = @"Loading...";
        
        [self reloadUI];
    }
    
    if (!_communities) {
        [_indicator startAnimating];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self retrieveTasks];
    });
}

- (void)refreshControlUsed:(id)sender {
    [self refresh];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    _selectedCommunity = 0;
    [self reloadUI];
    
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
    
    if (![PFUser currentUser]) {
        PFLogInViewController* logIn = [[PFLogInViewController alloc] init];
        logIn.delegate = self;
        
        PFSignUpViewController* signUp = [[PFSignUpViewController alloc] init];
        signUp.delegate = self;
        logIn.signUpController = signUp;
        
        [self presentViewController:logIn animated:NO completion:nil];
    }
}

- (void)newTaskPressed:(id)sender {
    assert([PFUser currentUser] != nil);
    
    if ([LocationSingleton sharedSingleton].geoPoint) {
        UINavigationController* navCon = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NewTaskViewController"];
        NewTaskViewController* VC = navCon.viewControllers[0];
        VC.user = [PFUser currentUser];
        VC.community = _communities[_selectedCommunity];
        
        assert(VC.user != nil);
        assert(VC.community != nil);
        
        [self presentViewController:navCon animated:YES completion:nil];
    } else {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Couldn't Determine Location" message:@"We can't post a task without your location. Wait a few seconds and try again." preferredStyle:UIAlertControllerStyleAlert];
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
    
    assert([annotation isKindOfClass:[LocationAnnotation class]]);
    
    MKPinAnnotationView* view = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"ID"];
    if (!view) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ID"];
    }
    
    view.canShowCallout = YES;
    view.tintColor = [self colorForCommunity:((LocationAnnotation*)annotation).task[@"community"]];
    
    return view;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (!_communities.count) {
        if (_communities) {
            return @"Create or Join a Community to See Tasks";
        } else {
            return @"Loading...";
        }
    }
    
    NSArray* tasks = _tasks[[_communities[_selectedCommunity] objectId]];
    if (tasks.count) {
        return [NSString stringWithFormat:@"%lu Tasks", (unsigned long)tasks.count];
    } else {
        return @"No Tasks in This Community";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ExamineTaskViewController* VC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ExamineTaskViewController"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        PFObject* community = _communities[_selectedCommunity];
        NSArray* tasks = _tasks[community.objectId];
        VC.task = tasks[indexPath.row];
        
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
    
    NSArray* tasks = [self tasksForCurrentCommunity];
    
    if (tasks.count) {
        PFObject* task = tasks[indexPath.row];
        PFGeoPoint* geoPoint = task[@"postLocation"];
        CLLocation* location = [[CLLocation alloc] initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude];
        
        cell.textLabel.text = task[@"title"];
        cell.detailTextLabel.text = [[LocationSingleton sharedSingleton] distanceTo:location];
        
        if ([((PFUser*)task[@"poster"]).objectId isEqualToString:[PFUser currentUser].objectId]) {
            cell.imageView.image = [UIImage imageNamed:@"Star"];
        } else {
            cell.imageView.image = nil;
        }
        
        cell.userInteractionEnabled = YES;
    } else {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
        cell.userInteractionEnabled = NO;
        cell.imageView.image = nil;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self tasksForCurrentCommunity].count ? [self tasksForCurrentCommunity].count : 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _lastUsername = [[PFUser currentUser].username copy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([PFUser currentUser]) {
        [self refresh];
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
