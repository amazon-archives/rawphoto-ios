//
//  AppDelegate.h
//  RawPhoto
//
//  Created by kaolin fire on 4/10/13.
//  Copyright (c) 2013 Blindsight. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AppDelegate;

@protocol DropboxUserLoggedInDelegate
- (void)dropboxUserLoggedIn:(AppDelegate*) delegate;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
	NSString *relinkUserId; // dropbox
}

@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) id <DropboxUserLoggedInDelegate> delegate;

@end
