#import <AVFoundation/AVFoundation.h>

#define kImageCapturedSuccessfully @"imageCapturedSuccessfully"

@interface CaptureSessionManager : NSObject {
@private
	AVCaptureDevice *camera;
	AVCaptureDeviceInput *cameraInput;
	AVCaptureInputPort *inputPort;
}

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain) AVCaptureSession *captureSession;
@property (retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, retain) UIImage *stillImage;

- (void)setVideoDevice:(AVCaptureDevice*)captureDevice andPreset:(const NSString*)capturePreset;
- (void)addVideoPreviewLayer;
- (void)addStillImageOutput;
- (void)captureStillImage;
- (void)addVideoInputFrontCamera:(BOOL)front;
- (void)stopRunning;
- (CMFormatDescriptionRef) formatDescription;

@end
