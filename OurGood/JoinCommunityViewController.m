//
//  JoinCommunityViewController.m
//  OurGood
//
//  Created by Eric Mitchell on 1/29/16.
//  Copyright © 2016 OurGood. All rights reserved.
//

#import "JoinCommunityViewController.h"
#import <Parse/Parse.h>

@interface JoinCommunityViewController ()

@property (nonatomic, strong) NSArray* communities;

@end

@implementation JoinCommunityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"All Communities";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    
    [self retrieveCommunities];
}

- (void)cancel {
    if ([_delegate respondsToSelector:@selector(joinCommunityViewControllerDidCancel:)]) {
        [_delegate joinCommunityViewControllerDidCancel:self];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)retrieveCommunities {
    PFQuery* communityQuery = [PFQuery queryWithClassName:@"Community"];
    [communityQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR RETRIEVING ALL COMMUNITIES: %@", error.localizedDescription);
            return;
        }
        
        _communities = objects;
        
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _communities ? _communities.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    if (_communities) {
        assert(indexPath.row < _communities.count);
        
        cell.textLabel.text = _communities[indexPath.row][@"name"];
        cell.detailTextLabel.text = _communities[indexPath.row][@"description"];
        cell.accessoryView = nil;
    } else {
        cell.textLabel.text = @"Loading Communities...";
        
        UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [indicator startAnimating];
        cell.accessoryView = indicator;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    assert(indexPath.row < _communities.count);
    
    if ([_delegate respondsToSelector:@selector(joinCommunityViewController:didSelectCommunity:)]) {
        [_delegate joinCommunityViewController:self didSelectCommunity:_communities[indexPath.row]];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
