//
//  MainViewController.m
//  RawPhoto
//
//  Created by kaolin fire on 4/10/13.
//  Copyright (c) 2013 Blindsight. All rights reserved.
//

#import "MainViewController.h"
#import "MBProgressHUD.h"
#import <DropboxSDK/DropboxSDK.h>
#import "UIDevice-Hardware.h"
#import "GAI.h"

#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

static NSDictionary *video_device_presets;

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize shutterButton;
@synthesize captureManager;
@synthesize restClient;

+ (NSDictionary*) video_device_presets {
	if (!video_device_presets) {
		video_device_presets = @{
													 @"Photo" : AVCaptureSessionPresetPhoto,
							@"High": AVCaptureSessionPresetHigh,
							@"Medium": AVCaptureSessionPresetMedium,
							@"Low": AVCaptureSessionPresetLow,
							@"352x288 (CIF)": AVCaptureSessionPreset352x288,
							@"640x480 (VGA)": AVCaptureSessionPreset640x480,
							@"1280x720": AVCaptureSessionPreset1280x720,
							@"1920x1080": AVCaptureSessionPreset1920x1080,
							@"960x540 (iFrame)": AVCaptureSessionPresetiFrame960x540,
							@"1280x720 (iFrame)": AVCaptureSessionPresetiFrame1280x720
							};
	}
	return video_device_presets;
}

- (void) deviceSelected:(id)sender {
	[self updateResolutionOptions];
	[_resolutionOptionsControl setSelectedSegmentIndex:-1];
}

- (void) resolutionSelected:(id)sender {
	NSArray *video_devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	NSString *selectedDeviceString = [_deviceOptionsControl titleForSegmentAtIndex:[_deviceOptionsControl selectedSegmentIndex]];
	AVCaptureDevice *selectedDevice;
	for (AVCaptureDevice *video_device in video_devices) {
		if ([[video_device localizedName] isEqualToString:selectedDeviceString]) {
			selectedDevice = video_device;
		}
	}
	NSInteger selectedIndex = [_resolutionOptionsControl selectedSegmentIndex];
	NSString *selectedPresetString = [_resolutionOptionsControl titleForSegmentAtIndex:selectedIndex];
	NSString *selectedPreset = [video_device_presets valueForKey:selectedPresetString];
	[[self captureManager] setVideoDevice:selectedDevice andPreset:selectedPreset];
	id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
	[tracker sendEventWithCategory:@"uiAction"
											withAction:@"resolutionSelected"
											 withLabel:selectedPreset
											 withValue:[NSNumber numberWithInt:0]];
	
}

-(void) updateResolutionOptions {
	NSString *selectedDevice = [_deviceOptionsControl titleForSegmentAtIndex:[_deviceOptionsControl selectedSegmentIndex]];
	NSArray *video_devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	[_resolutionOptionsControl removeAllSegments];
	for (AVCaptureDevice *video_device in video_devices) {
		if ([[video_device localizedName] isEqualToString:selectedDevice]) {
			for (NSString *preset_key in [[MainViewController video_device_presets] allKeys]) {
				//do what you want to do with items
				if ([video_device supportsAVCaptureSessionPreset:[video_device_presets objectForKey:preset_key]]) {
					[_resolutionOptionsControl insertSegmentWithTitle:preset_key atIndex:[_resolutionOptionsControl numberOfSegments] animated:NO];
				}
			}
		}
	}
	CGRect optionsFrame = _resolutionOptionsControl.frame;
	[_resolutionOptionsControl setFrame:CGRectMake(optionsFrame.origin.x, optionsFrame.origin.y, optionsFrame.size.width, [_resolutionOptionsControl numberOfSegments] * 25)];
//	[_resolutionOptionsControl sizeToFit];
}

- (void) startCamera {
	[self setCaptureManager:[[CaptureSessionManager alloc] init]];
//#warn make this user-selectable
	[[self captureManager] addVideoInputFrontCamera:NO]; // set to YES for Front Camera, No for Back camera
  [[self captureManager] addStillImageOutput];
	[[self captureManager] addVideoPreviewLayer];
	//	CGRect layerRect = [[[self view] layer] bounds];
	//	[[[self captureManager] previewLayer] setBounds:layerRect];
	//	[[[self captureManager] pwithreviewLayer] setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
	[self.view.layer insertSublayer:[[self captureManager] previewLayer] atIndex:0];
	[[[self captureManager] previewLayer] setHidden:YES];
	[[captureManager captureSession] startRunning];
}

- (void) takePicture:(id)sender {
	[shutterButton setEnabled:NO];
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	hud.labelText = @"Copying";
  [[self captureManager] captureStillImage];
}

- (void) useLiveImage {
	UIImage *image = [[self captureManager] stillImage];
	// re-drawing image to render out "rotation"
	UIGraphicsBeginImageContext(image.size);
	[image drawAtPoint:CGPointZero];
	image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
	[tracker sendEventWithCategory:@"uiAction"
											withAction:@"pictureTaken"
											 withLabel:NSStringFromCGSize(image.size)
											 withValue:[NSNumber numberWithInt:[[DBSession sharedSession] isLinked]?1:0]];
	// work up path/filename for saving locally
	NSString *platformString = [[[UIDevice currentDevice] platform] stringByReplacingOccurrencesOfString:@"," withString:@"x"];
	NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyyMMdd_HHmmss"];
	NSString *imageName = [NSString stringWithFormat:@"%@-%@.png",[dateFormatter stringFromDate:date],platformString];
	NSString *imageFile = [docsDir stringByAppendingPathComponent:imageName];
#pragma warn - do this not-atomically, have error handling!
	[UIImagePNGRepresentation(image) writeToFile:imageFile atomically:YES];
	// move to dropbox if that's linked
	if ([[DBSession sharedSession] isLinked]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			DBRestClient *client = [self restClient];
			client.delegate = self;
			[client uploadFile:imageName toPath:@"/" withParentRev:nil fromPath:imageFile];
		});
		// BELOW: "sync" API
//		DBPath *newPath = [[DBPath root] childPath:imageName];
//		DBFile *dbfile = [[DBFilesystem sharedFilesystem] createFile:newPath error:nil];
//		[dbfile writeContentsOfFile:imageFile shouldSteal:YES error:nil];
#pragma warn handle (DBError **)error!
	}
	// and be done with it :)
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	[shutterButton setEnabled:YES];
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (DBRestClient*)restClient {
	if (restClient == nil) {
		restClient = [((DBRestClient *)[DBRestClient alloc]) initWithSession:[DBSession sharedSession]];
		restClient.delegate = self;
	}
	return restClient;
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
							from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
	NSLog(@"File uploaded successfully to path: %@", metadata.path);
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:srcPath error:NULL];
	id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
	[tracker sendEventWithCategory:@"uiResult"
											withAction:@"dropboxUpload"
											 withLabel:@"success"
											 withValue:[NSNumber numberWithInt:0]];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
	id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
	[tracker sendEventWithCategory:@"uiResult"
											withAction:@"dropboxUpload"
											 withLabel:@"failure"
											 withValue:[NSNumber numberWithInt:0]];
	NSLog(@"File upload failed with error - %@", error);
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath {
//	NSLog(@"File upload progress: %@ — %f", destPath, progress);
}

#pragma mark - Camera Management =/

- (void)viewDidLoad {
	[super viewDidLoad];
	self.trackedViewName = @"Main";
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(useLiveImage) name:kImageCapturedSuccessfully object:nil];
	AppDelegate* delegate =(AppDelegate*)[[UIApplication sharedApplication] delegate];
	[delegate setDelegate:self];
	[_cameraIndicator setHidden:YES];
	NSString*	bundle = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString*	version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSString* versionText = [NSString stringWithFormat:@"%@ (%@)",version,bundle];
#if DEBUG
	NSString *platform =  [[UIDevice currentDevice] platform];
	versionText = [NSString stringWithFormat:@"%@ - debug #%@",versionText,platform];
#elif ADHOC
	versionText = [NSString stringWithFormat:@"%@ - adhoc",versionText];
#endif
	[self.versionLabel setText:versionText];
	
	// GET CAMERA INFO
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resolutionUpdated:) name:@"AVCaptureInputPortFormatDescriptionDidChangeNotification" object:nil];
	NSArray *video_devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	[_deviceOptionsControl removeAllSegments];
	AVCaptureDevice *defaultDevice =  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *video_device in video_devices) {
		[_deviceOptionsControl insertSegmentWithTitle:[video_device localizedName] atIndex:[_deviceOptionsControl numberOfSegments] animated:NO];
		if (video_device == defaultDevice) {
			[_deviceOptionsControl setSelectedSegmentIndex:[_deviceOptionsControl numberOfSegments]-1];
			[self updateResolutionOptions];
		}
		if ([video_device position] == AVCaptureDevicePositionBack) { // Back, Front, Unspecified
		} else if([video_device position] == AVCaptureDevicePositionFront) {
		} else {
		}
	}
	[_deviceOptionsControl sizeToFit];
	[_resolutionOptionsControl setSegmentedControlStyle:UISegmentedControlStylePlain]; // Bezeled, Bar, Bordered, Plain
	[_resolutionOptionsControl setLayoutOrientation:URBSegmentedControlOrientationVertical];
	[_resolutionOptionsControl setShowsGradient:NO];
	[_resolutionOptionsControl setBackgroundColor:[UIColor clearColor]];
	[_resolutionOptionsControl addTarget:self action:@selector(resolutionSelected:) forControlEvents:UIControlEventValueChanged];
	[_resolutionOptionsControl setAlpha:0.8];
	[_resolutionOptionsControl setSegmentBackgroundColor:[[[[UIApplication sharedApplication] delegate] window] tintColor]];
}

-(void)resolutionUpdated:(NSNotification*)sender {
	CMFormatDescriptionRef formatDescription = [[self captureManager] formatDescription];
	CMVideoDimensions formatDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
	[_resolutionLabel setText:[NSString stringWithFormat:@"%dx%d",formatDimensions.width,formatDimensions.height]];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[shutterButton setEnabled:NO];
	[_resolutionLabel setText:@""];
	[self fixCameraIndicator:self.interfaceOrientation];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
#if !(TARGET_IPHONE_SIMULATOR)
	[self startCamera];
	[shutterButton setEnabled:YES];
#else
	[shutterButton setHidden:YES];
#endif
	
#if !(TARGET_IPHONE_SIMULATOR)
	[UIView setAnimationsEnabled:NO];
	//	[[self captureManager] previewLayer].frame = self.view.frame;
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		[[self captureManager] previewLayer].frame = CGRectMake(0,0,self.view.frame.size.height,self.view.frame.size.width);
	} else {
		[[self captureManager] previewLayer].frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
	}
	// @TODO: setVideoOrientation instead! =/
	[[[self captureManager] previewLayer] setOrientation:self.interfaceOrientation];
	
	//[[[self captureManager] previewLayer] setOpacity:0];
	[UIView setAnimationsEnabled:YES];
	[CATransaction flush];
	[[[self captureManager] previewLayer] setHidden:NO];
	
	//	[[[self captureManager] previewLayer] setOpacity:1.0];
#endif
}

- (void)viewDidDisappear:(BOOL)animated {
#if !(TARGET_IPHONE_SIMULATOR)
	[[[self captureManager] previewLayer] removeFromSuperlayer];
#endif
}

- (void) stopCamera {
	[captureManager stopRunning];
}

- (void)viewDidUnload{
	[self setShutterButton:nil];
	[self setCameraIndicator:nil];
	[super viewDidUnload];
	[self cleanup];
}

- (void) cleanup {
#if !(TARGET_IPHONE_SIMULATOR)
	[captureManager stopRunning];
	captureManager = nil;
#endif
}

- (void) dealloc {
	[self cleanup];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
#if !(TARGET_IPHONE_SIMULATOR)
	[UIView setAnimationsEnabled:NO];
	[UIView setAnimationsEnabled:YES];
#endif
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
#if !(TARGET_IPHONE_SIMULATOR)
	[[[self captureManager] previewLayer] setHidden:NO];
#endif
}

- (void)fixCameraIndicator:(UIInterfaceOrientation)orientation {
	CGRect ideal=CGRectMake(_cameraIndicator.frame.size.width,_cameraIndicator.frame.size.height,_cameraIndicator.frame.size.width,_cameraIndicator.frame.size.height); // offsets x, y; size width, height
	float width, height;
	if (self.view.frame.size.height > self.view.frame.size.width) {
		width = self.view.frame.size.height;
		height = self.view.frame.size.width;
	} else {
		width = self.view.frame.size.width;
		height = self.view.frame.size.height;
	}
	int transformDegrees = 0;
	switch (orientation) {
		case UIInterfaceOrientationLandscapeLeft:
			[_cameraIndicator setFrame:CGRectMake(width - ideal.origin.x - ideal.size.width /2, height - ideal.size.height - ideal.origin.y /2,ideal.size.width,ideal.size.height)];
			transformDegrees = 90;
			break;
		case UIInterfaceOrientationLandscapeRight:
			[_cameraIndicator setFrame:CGRectMake(ideal.origin.x - ideal.size.width/2,ideal.origin.y - ideal.size.height/2,ideal.size.width,ideal.size.height)];
			transformDegrees = -90;
			break;
		case UIInterfaceOrientationPortrait:
			[_cameraIndicator setFrame:CGRectMake(height - ideal.origin.x - ideal.size.width / 2,ideal.origin.y - ideal.size.height / 2,ideal.size.width,ideal.size.height)];
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			[_cameraIndicator setFrame:CGRectMake(ideal.origin.x - ideal.size.width/2,self.view.frame.size.height - ideal.origin.y - ideal.size.height / 2,ideal.size.width,ideal.size.height)];
			transformDegrees = 180;
			break;
	}
//	CGAffineTransform cgCTM = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(transformDegrees));
//	_cameraIndicator.transform = cgCTM;
//	NSLog(@"%@",NSStringFromCGRect(_cameraIndicator.frame));
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
#if !(TARGET_IPHONE_SIMULATOR)
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		[[self captureManager] previewLayer].frame = CGRectMake(0,0,self.view.frame.size.height,self.view.frame.size.width);
	} else {
		[[self captureManager] previewLayer].frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
	}
	[[[self captureManager] previewLayer] setOrientation:toInterfaceOrientation];
	// 2012-08-06 11:19:47.569 Magnifier[18057:907] WARNING: -[<AVCaptureVideoPreviewLayer: 0x200df930> setOrientation:] is deprecated.  Please use AVCaptureConnection's -setVideoOrientation:
	[[[self captureManager] previewLayer] setHidden:YES];
#endif
	[self fixCameraIndicator:toInterfaceOrientation];
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - AppDelegate delagation
- (void)dropboxUserLoggedIn:(AppDelegate*) delegate {
	if (self.flipsidePopoverController) {
		[self.flipsidePopoverController dismissPopoverAnimated:YES];
		self.flipsidePopoverController = nil;		
	}
	id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
	[tracker sendEventWithCategory:@"uiAction"
											withAction:@"dropboxToggle"
											 withLabel:@"enabled"
											 withValue:0];
}

#pragma mark - Flipside View Controller

- (void)dropboxLinkDidChange:(FlipsideViewController *)controller {
	restClient = nil;
	[self flipsideViewControllerDidFinish:nil];
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[self dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self.flipsidePopoverController dismissPopoverAnimated:YES];
		self.flipsidePopoverController = nil;
	}
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	self.flipsidePopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([[segue identifier] isEqualToString:@"showAlternate"]) {
		[[segue destinationViewController] setDelegate:self];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
			self.flipsidePopoverController = popoverController;
			popoverController.delegate = self;
		}
	}
}

- (IBAction)togglePopover:(id)sender {
	if (self.flipsidePopoverController) {
		[self.flipsidePopoverController dismissPopoverAnimated:YES];
		self.flipsidePopoverController = nil;
	} else {
		[self performSegueWithIdentifier:@"showAlternate" sender:sender];
	}
}

@end
