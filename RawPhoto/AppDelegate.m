//
//  AppDelegate.m
//  RawPhoto
//
//  Created by kaolin fire on 4/10/13.
//  Copyright (c) 2013 Blindsight. All rights reserved.
//

#import "AppDelegate.h"
#import <DropboxSDK/DropboxSDK.h>
#import "UIDevice-Hardware.h"
#import "GAI.h"

@interface AppDelegate () <DBSessionDelegate, DBNetworkRequestDelegate>

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSString *root = kDBRootAppFolder; // Should be set to either kDBRootAppFolder or kDBRootDropbox
	NSString* errorMsg = nil;
	NSString *appKey = DROPBOX_APPKEY;
	NSString *appSecret = DROPBOX_APPSECRET;
	if ([appKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app key correctly in your app delegate";
	} else if ([appSecret rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app secret correctly in your app delegate";
	} else if ([root length] == 0) {
		errorMsg = @"Set your root to use either App Folder of full Dropbox";
	} else {
		NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
		NSData *plistData = [NSData dataWithContentsOfFile:plistPath];
		NSDictionary *loadedPlist =
		[NSPropertyListSerialization
		 propertyListFromData:plistData mutabilityOption:0 format:NULL errorDescription:NULL];
		NSString *scheme = [[[[loadedPlist objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
		if (![scheme isEqual:[NSString stringWithFormat:@"db-%@",appKey]]) {
			errorMsg = @"Set your URL scheme correctly in your application plist";
		}
	}
	NSLog(@"Device: %@ (%@)",[[UIDevice currentDevice] platformString], [[UIDevice currentDevice] platform]);
	
	DBSession* session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
	session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
	[DBSession setSharedSession:session];
	
	[DBRequest setNetworkRequestDelegate:self];
	
	if (errorMsg != nil) {
		[[[UIAlertView alloc]
		   initWithTitle:@"Error Configuring Session" message:errorMsg
		   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
		 show];
	}
	
	NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
	NSInteger majorVersion =
	[[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] integerValue];
	if (launchURL && majorVersion < 4) {
		// Pre-iOS 4.0 won't call application:handleOpenURL; this code is only needed if you support
		// iOS versions 3.2 or below
		[self application:application handleOpenURL:launchURL];
		return NO;
	}
//	NSLog(@"TODO: IF DROPBOX IS LINKED, START UPLOADING FILES!!!!");
	// GOOGLE ANALYTICS
  // Optional: automatically send uncaught exceptions to Google Analytics.
  [GAI sharedInstance].trackUncaughtExceptions = YES;
  // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
  [GAI sharedInstance].dispatchInterval = 20;
  // Optional: set debug to YES for extra debugging information.
  [GAI sharedInstance].debug = YES;
  // Create tracker instance.
  id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GOOGLE_ANALYTICS_TRACKING_ID];

	return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	if ([[DBSession sharedSession] handleOpenURL:url]) {
		if ([[DBSession sharedSession] isLinked]) {
//			[navigationController pushViewController:rootViewController.photoViewController animated:YES];
		}
		[self.delegate dropboxUserLoggedIn:self];
		return YES;
	}
	return NO;
}

#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
	relinkUserId = userId;
	[[[UIAlertView alloc]
	   initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self
	   cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil]
	 show];
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
	if (index != alertView.cancelButtonIndex) {
		[[DBSession sharedSession] linkUserId:relinkUserId fromController:nil];
	}
	relinkUserId = nil;
}


#pragma mark -
#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted {
	outstandingRequests++;
	if (outstandingRequests == 1) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
}

- (void)networkRequestStopped {
	outstandingRequests--;
	if (outstandingRequests == 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}


- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
