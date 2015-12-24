//
//  LocationSingleton.m
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import "LocationSingleton.h"
#import <Parse/Parse.h>

@implementation LocationSingleton

#define MAX_MINUTES 15
#define METERS_TO_MILES 0.000621371

- (void)retrieveLocation {
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint * _Nullable geoPoint, NSError * _Nullable error) {
        if (!error) {
            if (geoPoint) {
                _geoPoint = geoPoint;
                _timestamp = [NSDate date];
            }
        } else {
            NSLog(@"ERROR ACQUIRING LOCATION: %@", error);
        }
    }];
}

+ (LocationSingleton*)sharedSingleton {
    static LocationSingleton* sharedSingleton;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[LocationSingleton alloc] init];
    });
    
    [sharedSingleton retrieveLocation];
    
    return sharedSingleton;
}

- (NSString*)distanceTo:(CLLocation*)location {
    if (_geoPoint) {
        CLLocationDistance distance = [location distanceFromLocation:[[CLLocation alloc] initWithLatitude:_geoPoint.latitude longitude:_geoPoint.longitude]];
        
        CLLocationDistance miles = distance * METERS_TO_MILES;
        
        return [NSString stringWithFormat:@"%.2f mi", miles];
    } else {
        return nil;
    }
}

- (PFGeoPoint*)geoPoint {
    if (_geoPoint && [[NSDate date] timeIntervalSinceDate:_timestamp] < 60 * MAX_MINUTES) {
        return _geoPoint;
    } else {
        [self retrieveLocation];
        return nil;
    }
}

@end
