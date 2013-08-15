//
//  FlipsideViewController.h
//  RawPhoto
//
//  Created by kaolin fire on 4/10/13.
//  Copyright (c) 2013 Blindsight. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"

@class FlipsideViewController;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

@protocol DropboxLinkControllerDelegate
- (void)dropboxLinkDidChange:(FlipsideViewController*) controller;
@end

@interface FlipsideViewController : GAITrackedViewController

@property (weak, nonatomic) id <FlipsideViewControllerDelegate,DropboxLinkControllerDelegate> delegate;

@property (retain, nonatomic) IBOutlet UIButton *dropboxButton;

- (IBAction)done:(id)sender;
- (IBAction)toggleDropbox:(id)sender;
- (IBAction)launchTwitter:(id)sender;
- (IBAction)launchFacebook:(id)sender;

@end
