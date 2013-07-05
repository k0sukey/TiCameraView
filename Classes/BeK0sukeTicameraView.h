/**
 * BeK0sukeTicameraView.h
 */

#import "TiUIView.h"
#import "GPUImage.h"
#import <AVFoundation/AVFoundation.h>

@interface BeK0sukeTicameraView : TiUIView<AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
@private
    KrollCallback *successPictureCallback;
    KrollCallback *errorPictureCallback;
    KrollCallback *successRecordingCallback;
    KrollCallback *errorRecordingCallback;
    BOOL *isRecording;
    NSURL *recordingUrl;
    CGSize recordingSize;
    NSInteger __block recordingFrame;
    BOOL *isInterval;
    BOOL *intervalSaveToPhotoGallery;
    BOOL *intervalShutterSound;
    BOOL *adjustingExposure;
    
    BOOL *isSepia;
}

@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureSession *videoSession;
@property (nonatomic, strong) UIImageView *videoPreview;
@property (nonatomic, strong) NSMutableArray *recordingBuffer;
@property (nonatomic, strong) AVAssetWriter *recordingWriter;
@property (nonatomic, strong) AVAssetWriterInput *recordingInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *recordingAdaptor;
@property (nonatomic, strong) NSTimer *intervalTimer;

-(id)isFrontCamera:(id)args;
-(id)isBackCamera:(id)args;
-(id)isTorch:(id)args;

-(void)toggleCamera:(id)args;
-(void)toggleTorch:(id)args;

-(void)takePicture:(id)args;
-(void)startRecording:(id)args;
-(void)stopRecording:(id)args;
-(void)startInterval:(id)args;
-(void)stopInterval:(id)args;

@end
