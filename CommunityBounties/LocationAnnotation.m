//
//  LocationAnnotation.m
//  CommunityBounties
//
//  Created by Eric Mitchell on 11/14/15.
//  Copyright © 2015 Eric Mitchell. All rights reserved.
//

#import "LocationAnnotation.h"
#import "LocationSingleton.h"

@implementation LocationAnnotation

- (NSString*)title {
    return _task[@"title"];
}

- (NSString*)subtitle {
    PFGeoPoint* geoPoint = _task[@"postLocation"];
    CLLocation* location = [[CLLocation alloc] initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude];
    
    return [[LocationSingleton sharedSingleton] distanceTo:location];
}

@end
