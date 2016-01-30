//
//  JoinCommunityViewController.h
//  OurGood
//
//  Created by Eric Mitchell on 1/29/16.
//  Copyright © 2016 OurGood. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PFObject;
@class JoinCommunityViewController;

@protocol JoinCommunityViewControllerDelegate <NSObject>

@optional

- (void)joinCommunityViewControllerDidCancel:(JoinCommunityViewController*)viewController;
- (void)joinCommunityViewController:(JoinCommunityViewController*)viewController didSelectCommunity:(PFObject*)community;

@end

@interface JoinCommunityViewController : UITableViewController

@property (nonatomic, weak) id<JoinCommunityViewControllerDelegate> delegate;

@end
