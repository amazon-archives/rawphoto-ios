#import "CaptureSessionManager.h"
#import <ImageIO/ImageIO.h>

@implementation CaptureSessionManager

@synthesize captureSession;
@synthesize previewLayer;
@synthesize stillImageOutput;
@synthesize stillImage;


// #define CAPTURE_JPEG

#pragma mark Capture Session Configuration

- (id)init {
	if ((self = [super init])) {
		[self setCaptureSession:[[AVCaptureSession alloc] init]];
		[[self captureSession] setSessionPreset:AVCaptureSessionPresetPhoto];
	}
	return self;
}

- (void)addVideoPreviewLayer {
	[self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self captureSession]]];
	[[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspect];
}

- (void)addVideoInputFrontCamera:(BOOL)front {
	NSArray *devices = [AVCaptureDevice devices];
	AVCaptureDevice *frontCamera = NULL;
	AVCaptureDevice *backCamera = NULL;
	
	for (AVCaptureDevice *device in devices) {
		
		NSLog(@"Device name: %@", [device localizedName]);
		
		if ([device hasMediaType:AVMediaTypeVideo]) {
			
			if ([device position] == AVCaptureDevicePositionBack) {
				NSLog(@"Device position : back");
				backCamera = device;
			}
			else {
				NSLog(@"Device position : front");
				frontCamera = device;
			}
		}
	}
	
	NSError *error = nil;
	
	if (front) {
		AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
		if (!error) {
			if ([[self captureSession] canAddInput:frontFacingCameraDeviceInput]) {
				[[self captureSession] addInput:frontFacingCameraDeviceInput];
				cameraInput = frontFacingCameraDeviceInput;
				camera = frontCamera;
			} else {
				NSLog(@"Couldn't add front facing video input");
			}
		}
	} else {
		AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
		if (!error) {
			if ([[self captureSession] canAddInput:backFacingCameraDeviceInput]) {
				[[self captureSession] addInput:backFacingCameraDeviceInput];
				cameraInput = backFacingCameraDeviceInput;
				camera = backCamera;
			} else {
				NSLog(@"Couldn't add back facing video input");
			}
		}
	}
}

- (void)setVideoDevice:(AVCaptureDevice*)captureDevice andPreset:(NSString*)capturePreset {
	NSError *error;
	[[self captureSession] beginConfiguration];
	[[self captureSession] removeInput:cameraInput];
	[[self captureSession] setSessionPreset:capturePreset];
	cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
	[[self captureSession] addInput:cameraInput];
	[[self captureSession] commitConfiguration];
}

- (CMFormatDescriptionRef) formatDescription {
  for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
    for (AVCaptureInputPort *port in [connection inputPorts]) {
      if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
        return [port formatDescription];
			}
		}
	}
	return nil;
}

- (void)addStillImageOutput {
  [self setStillImageOutput:[[AVCaptureStillImageOutput alloc] init]];
#ifdef CAPTURE_JPEG
  NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
#else
	NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, nil];
#endif
	NSArray *availableSettings = [[self stillImageOutput] availableImageDataCodecTypes];
  NSLog(@"%@",availableSettings);
	[[self stillImageOutput] setOutputSettings:outputSettings];
  AVCaptureConnection *videoConnection = nil;
  for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
    for (AVCaptureInputPort *port in [connection inputPorts]) {
      if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
        videoConnection = connection;
				
        break;
      }
    }
    if (videoConnection) {
      break;
    }
  }
  
  [[self captureSession] addOutput:[self stillImageOutput]];
}

- (void)captureStillImage {
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
      break;
    }
	}
	// WAIT FOR FOCUS!!!!
	NSLog(@"about to request a capture from: %@", [self stillImageOutput]);
	if ([camera isAdjustingFocus]) {
		NSLog(@"ADJUSTING");
		[NSThread sleepForTimeInterval:0.1f];
		[self performSelectorInBackground:@selector(captureStillImage) withObject:nil];
		return;
	}
#ifndef CAPTURE_JPEG
	UIImageOrientation orientation;
	switch ([[UIApplication sharedApplication] statusBarOrientation]) {
		case UIInterfaceOrientationLandscapeLeft:  orientation = UIImageOrientationDown; break;
		case UIInterfaceOrientationLandscapeRight:  orientation = UIImageOrientationUp; break;
		case UIInterfaceOrientationPortrait:  orientation = UIImageOrientationRight; break;
		case UIInterfaceOrientationPortraitUpsideDown:  orientation = UIImageOrientationLeft; break;
		default:
			NSLog(@"UNHANDLED ROTATION / DEVICE ORIENTATION: %d",[[UIDevice currentDevice] orientation]);
	}
#endif
	[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                         CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
                                                         if (exifAttachments) {
                                                           NSLog(@"attachments: %@", exifAttachments);
                                                         } else {
                                                           NSLog(@"no attachments");
                                                         }
#ifdef CAPTURE_JPEG
                                                         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                         UIImage *image = [[UIImage alloc] initWithData:imageData];
#else
																												 CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(imageSampleBuffer);
																												 CVPixelBufferLockBaseAddress(imageBuffer,0);
																												 uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
																												 size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
																												 size_t width = CVPixelBufferGetWidth(imageBuffer);
																												 size_t height = CVPixelBufferGetHeight(imageBuffer);
																												 CVPixelBufferUnlockBaseAddress(imageBuffer,0);
																												 CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
																												 CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
																												 CGImageRef newImage = CGBitmapContextCreateImage(newContext);
																												 CGContextRelease(newContext);
																												 CGColorSpaceRelease(colorSpace);
																												 UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:orientation];
																												 CGImageRelease(newImage);
#endif
                                                         [self setStillImage:image];
                                                         [[NSNotificationCenter defaultCenter] postNotificationName:kImageCapturedSuccessfully object:nil];
                                                       }];
}

- (void)stopRunning {
	[[self captureSession] stopRunning];
}

- (void)dealloc {
	[[self captureSession] stopRunning];
}

@end
