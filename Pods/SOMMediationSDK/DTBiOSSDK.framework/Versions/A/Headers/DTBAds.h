//
//  DTBAds.h
//  DTBiOSSDK
//
//  Created by Singh, Prashant Bhushan on 1/30/15.
//  Copyright (c) 2015 amazon.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTBLog.h"

@interface DTBAds : NSObject

@property (nonatomic) BOOL useSecureConnection;
@property (nonatomic) BOOL testMode;
@property (nonatomic) BOOL useGeoLocation;

+ (DTBAds * _Nonnull)sharedInstance;

// Set the applicationId provided by the Amazon Appstore.
- (void)setAppKey:(NSString * _Nonnull)appKey;

// Retrieves the appKey, if already stored, otherwise will throw an exception
- (NSString * _Nullable)appKey;

- (void)setLogLevel: (DTBLogLevel)logLevel;

- (BOOL)handleURL: (NSURL *  _Nonnull)url;

+ (NSString * _Nonnull)version;

@end
