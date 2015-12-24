//
//  LocationSingleton.h
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface LocationSingleton : NSObject {
    PFGeoPoint* _geoPoint;
    NSDate* _timestamp;
}

- (NSString*)distanceTo:(CLLocation*)location;
+ (LocationSingleton*)sharedSingleton;
- (PFGeoPoint*)geoPoint;

@end
