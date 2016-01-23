//
//  LocationAnnotation.h
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

@import Foundation;
@import MapKit;

#import <Parse/Parse.h>

@interface LocationAnnotation : NSObject<MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, weak) PFObject* task;

@end
