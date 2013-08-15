//
//  FlipsideViewController.m
//  RawPhoto
//
//  Created by kaolin fire on 4/10/13.
//  Copyright (c) 2013 Blindsight. All rights reserved.
//

#import "FlipsideViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "GAI.h"

@interface FlipsideViewController ()

@end

@implementation FlipsideViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.trackedViewName = @"Info";
	// Do any additional setup after loading the view, typically from a nib.
	self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
}

- (void) viewWillAppear:(BOOL)animated {
	[self updateDropboxText];
	[super viewWillAppear:animated];
}
#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (IBAction) toggleDropbox:(id)sender {
	if (![[DBSession sharedSession] isLinked]) {
		[[DBSession sharedSession] linkFromController:self];
	} else {
		[[DBSession sharedSession] unlinkAll];
		id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
		[tracker sendEventWithCategory:@"uiAction"
												withAction:@"dropboxToggle"
												 withLabel:@"enabled"
												 withValue:0];
    [self.delegate dropboxLinkDidChange:self];
	}
}

- (void) updateDropboxText {
	if (![[DBSession sharedSession] isLinked]) {
		[_dropboxButton setTitle:@"Link Dropbox" forState:UIControlStateNormal];
		[_dropboxButton setTitle:@"Link Dropbox" forState:UIControlStateHighlighted];
	} else {
		[_dropboxButton setTitle:@"UNLINK Dropbox" forState:UIControlStateNormal];
		[_dropboxButton setTitle:@"UNLINK Dropbox" forState:UIControlStateHighlighted];
	}
	[_dropboxButton sizeToFit];
}

-(IBAction)launchFacebook:(id)sender {
	id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
	[tracker sendEventWithCategory:@"uiAction"
											withAction:@"launchSocial"
											 withLabel:@"facebook"
											 withValue:0];
	NSURL *url = [NSURL URLWithString:@"fb://profile/402363766465648"];
	if (![[UIApplication sharedApplication] canOpenURL:url]) {
		url = [NSURL URLWithString: @"https://www.facebook.com/blindsightcorp"];
	}
	[[UIApplication sharedApplication] openURL:url];
}

-(IBAction)launchTwitter:(id)sender {
	id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
	[tracker sendEventWithCategory:@"uiAction"
											withAction:@"launchSocial"
											 withLabel:@"twitter"
											 withValue:0];
	NSURL *url = [NSURL URLWithString:@"https://twitter.com/blindsightcorp"];
	[[UIApplication sharedApplication] openURL:url];
}

@end