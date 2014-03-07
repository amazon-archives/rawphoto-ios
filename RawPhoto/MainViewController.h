//
//  MainViewController.h
//  RawPhoto
//
//  Created by kaolin fire on 4/10/13.
//  Copyright (c) 2013 Blindsight. All rights reserved.
//

#import "FlipsideViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CaptureSessionManager.h"
#import <DropboxSDK/DropboxSDK.h>
#import "AppDelegate.h"
#import "URBSegmentedControl.h"
#import "GAITrackedViewController.h"

@interface MainViewController : GAITrackedViewController <FlipsideViewControllerDelegate, UIPopoverControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, DBRestClientDelegate, DropboxLinkControllerDelegate, DropboxUserLoggedInDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property (retain) CaptureSessionManager *captureManager;
@property (retain, nonatomic) DBRestClient *restClient;

- (IBAction)takePicture:(id)sender;
- (void)fixCameraIndicator:(UIInterfaceOrientation)orientation;

@property (retain, nonatomic) IBOutlet UIButton *shutterButton;
@property (retain, nonatomic) IBOutlet UIView *cameraIndicator;
@property (retain, nonatomic) IBOutlet UILabel *versionLabel;
@property (retain, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (retain,nonatomic) IBOutlet UISegmentedControl *deviceOptionsControl;
@property (retain, nonatomic) IBOutlet URBSegmentedControl *resolutionOptionsControl;
- (IBAction)deviceSelected:(id)sender;
- (IBAction)resolutionSelected:(id)sender;

@end