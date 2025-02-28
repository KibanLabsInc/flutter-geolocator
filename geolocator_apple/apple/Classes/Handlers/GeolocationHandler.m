//
//  LocationManager.m
//  geolocator
//
//  Created by Maurits van Beusekom on 20/06/2020.
//

#import "GeolocationHandler.h"
#import "../Constants/ErrorCodes.h"

@interface GeolocationHandler() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) GeolocatorError errorHandler;
@property (strong, nonatomic) GeolocatorResult resultHandler;

@end

@implementation GeolocationHandler

- (CLLocation *)getLastKnownPosition {
    return [self.locationManager location];
}

- (void)requestPosition:(GeolocatorResult _Nonnull)resultHandler
           errorHandler:(GeolocatorError _Nonnull)errorHandler {
  self.errorHandler = errorHandler;
  self.resultHandler = resultHandler;
  
  if (@available(iOS 9.0, macOS 10.14, *)) {
    [self.locationManager requestLocation];
    return;
  }
  
  [self startUpdatingLocationWithDesiredAccuracy:kCLLocationAccuracyBest
                                  distanceFilter:kCLDistanceFilterNone
               pauseLocationUpdatesAutomatically:NO
                                    activityType:CLActivityTypeOther];
}

- (void)startListeningWithDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                           distanceFilter:(CLLocationDistance)distanceFilter
        pauseLocationUpdatesAutomatically:(BOOL)pauseLocationUpdatesAutomatically
                             activityType:(CLActivityType)activityType
                            resultHandler:(GeolocatorResult _Nonnull )resultHandler
                             errorHandler:(GeolocatorError _Nonnull)errorHandler {
    
    self.errorHandler = errorHandler;
    self.resultHandler = resultHandler;
    
  [self startUpdatingLocationWithDesiredAccuracy:desiredAccuracy
                                  distanceFilter:distanceFilter
               pauseLocationUpdatesAutomatically:pauseLocationUpdatesAutomatically
                                    activityType:activityType];
}

- (void)startUpdatingLocationWithDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                                  distanceFilter:(CLLocationDistance)distanceFilter
               pauseLocationUpdatesAutomatically:(BOOL)pauseLocationUpdatesAutomatically
                                    activityType:(CLActivityType)activityType {
  CLLocationManager *locationManager = self.locationManager;
  locationManager.desiredAccuracy = desiredAccuracy;
  locationManager.distanceFilter = distanceFilter;
  if (@available(iOS 6.0, macOS 10.15, *)) {
    locationManager.activityType = activityType;
    locationManager.pausesLocationUpdatesAutomatically = pauseLocationUpdatesAutomatically;
  }
  
#if TARGET_OS_IOS
  if (@available(iOS 9.0, macOS 11.0, *)) {
      locationManager.allowsBackgroundLocationUpdates = [GeolocationHandler shouldEnableBackgroundLocationUpdates];
  }
#endif
  
  [locationManager startUpdatingLocation];
}

- (void)stopListening {
    [self.locationManager stopUpdatingLocation];
    
    self.errorHandler = nil;
    self.resultHandler = nil;
}

- (CLLocationManager *) locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (!self.resultHandler) return;
    
    if ([locations lastObject]) {
        self.resultHandler([locations lastObject]);
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(nonnull NSError *)error {
    NSLog(@"LOCATION UPDATE FAILURE:"
          "Error reason: %@"
          "Error description: %@", error.localizedFailureReason, error.localizedDescription);
    
    if([error.domain isEqualToString:kCLErrorDomain] && error.code == kCLErrorLocationUnknown) {
        return;
    }

    if (self.errorHandler) {
        self.errorHandler(GeolocatorErrorLocationUpdateFailure, error.localizedDescription);
    }
}

+ (BOOL) shouldEnableBackgroundLocationUpdates {
    if (@available(iOS 9.0, *)) {
        return [[NSBundle.mainBundle objectForInfoDictionaryKey:@"UIBackgroundModes"] containsObject: @"location"];
    } else {
        return NO;
    }
}
@end
