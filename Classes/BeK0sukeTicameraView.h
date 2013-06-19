/**
 * BeK0sukeTicameraView.h
 */

#import "TiUIView.h"
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
}

@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureSession *videoSession;
@property (nonatomic, strong) UIImageView *videoPreview;
@property (nonatomic, strong) NSMutableArray *recordingBuffer;
@property (nonatomic, strong) AVAssetWriter *recordingWriter;
@property (nonatomic, strong) AVAssetWriterInput *recordingInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *recordingAdaptor;

-(void)toggleCamera:(id)args;
-(void)takePicture:(id)args;
-(void)startRecording:(id)args;
-(void)stopRecording:(id)args;

@end
