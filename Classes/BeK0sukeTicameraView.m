/**
 * BeK0sukeTicameraView.m
 */

#import "BeK0sukeTicameraView.h"

@implementation BeK0sukeTicameraView

-(void)dealloc
{
    RELEASE_TO_NIL(successPictureCallback);
    RELEASE_TO_NIL(errorPictureCallback);
    RELEASE_TO_NIL(successRecordingCallback);
    RELEASE_TO_NIL(errorRecordingCallback);
    
    [self.videoSession stopRunning];
    
    [super dealloc];
}

-(id)init
{
    self = [super init];
    
    if (self)
    {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self
                                                 action:@selector(tapDetected:)];
        [self addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
    }
    
    return self;
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
#ifndef __i386__
    if (self.videoPreview == nil)
    {
        self.videoPreview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,
                                                                     bounds.size.width,
                                                                     bounds.size.height)];
        [self addSubview:self.videoPreview];
    }
    
    [self setupAVCapture];
#endif
}

-(void)dispatchCallback:(NSArray*)args
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *type = [args objectAtIndex:0];
	id object = [args objectAtIndex:1];
	id listener = [args objectAtIndex:2];
	[self.proxy _fireEventToListener:type withObject:object listener:listener thisObject:nil];
	[pool release];
}

-(void)setupAVCapture
{
#ifndef __i386__
    NSError *error = nil;
    
    AVCaptureDevice *captureDevice = [self deviceWithPosition: [TiUtils intValue:[self.proxy valueForKey:@"cameraPosition"]
                                                                             def:AVCaptureDevicePositionBack]];
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    
    if (!self.videoInput)
    {
        NSLog(@"[ERROR] %@", error);
        return;
    }
    
    self.videoSession = [[AVCaptureSession alloc] init];
    [self.videoSession addInput:self.videoInput];
    
    [self.videoSession beginConfiguration];
    self.videoSession.sessionPreset = [TiUtils intValue:[self.proxy valueForKey:@"videoQuality"]
                                                    def:AVCaptureSessionPresetMedium];
    [self.videoSession commitConfiguration];
    
    [captureDevice addObserver:self
                    forKeyPath:@"adjustingExposure"
                       options:NSKeyValueObservingOptionNew
                       context:nil];
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoSession addOutput:self.videoOutput];
    
    dispatch_queue_t queue = dispatch_queue_create("be.k0suke.tilive.captureQueue", NULL);
    [self.videoOutput setAlwaysDiscardsLateVideoFrames:TRUE];
    [self.videoOutput setSampleBufferDelegate:self queue:queue];
    
    self.videoOutput.videoSettings = @{
                                       (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                       };
    
    AVCaptureConnection *videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoMinFrameDuration = CMTimeMake(1, [TiUtils intValue:[self.proxy valueForKey:@"frameDuration"]
                                                                        def:16]);
    
    [self.videoSession startRunning];
#endif
}

-(AVCaptureDevice *)deviceWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == position)
        {
            return Device;
        }
    }
    
    return nil;
}

-(void)takePicture:(id)args
{
#ifndef __i386__
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
    ENSURE_UI_THREAD(takePicture, args);
    
    successPictureCallback = [args objectForKey:@"success"];
	ENSURE_TYPE_OR_NIL(successPictureCallback, KrollCallback);
	[successPictureCallback retain];
    
    errorPictureCallback = [args objectForKey:@"error"];
	ENSURE_TYPE_OR_NIL(errorPictureCallback, KrollCallback);
	[errorPictureCallback retain];
    
    if ([TiUtils boolValue:[args valueForKey:@"shutterSound"] def:YES])
    {
        AudioServicesPlaySystemSound(1108);
    }
    
    if (self.videoPreview.image)
    {
        if ([TiUtils boolValue:[args valueForKey:@"saveToPhotoGallery"] def:NO])
        {
            UIImageWriteToSavedPhotosAlbum(self.videoPreview.image, self, nil, nil);
        }
        
        if (successPictureCallback != nil)
        {
            id listener = [[successPictureCallback retain] autorelease];
            NSMutableDictionary *event = [TiUtils dictionaryWithCode:0 message:nil];
            [event setObject:[[[TiBlob alloc] initWithImage:self.videoPreview.image] autorelease] forKey:@"media"];
            [NSThread detachNewThreadSelector:@selector(dispatchCallback:) toTarget:self withObject:[NSArray arrayWithObjects:@"success", event, listener, nil]];
        }
    }
    else
    {
        if (errorPictureCallback != nil)
        {
            id listener = [[errorPictureCallback retain] autorelease];
            NSMutableDictionary *event = [TiUtils dictionaryWithCode:-1 message:@"AVCaptureConnection connect failed"];
            [NSThread detachNewThreadSelector:@selector(dispatchCallback:) toTarget:self withObject:[NSArray arrayWithObjects:@"error", event, listener, nil]];
        }
    }
#endif
}

-(void)startRecording:(id)args
{
#ifndef __i386__
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
    ENSURE_UI_THREAD(startRecording, args);
    
    if (isRecording)
    {
        NSLog(@"[WARN] video recording started");
        return;
    }
    
    recordingFrame = 0;
    self.recordingBuffer = [[NSMutableArray array] mutableCopy];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"yyyyMMddHHmmss";
    recordingUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@_%@%@",
                                           NSTemporaryDirectory(),
                                           @"output",
                                           [format stringFromDate:[NSDate date]],
                                           @".mov"]];
    recordingSize = CGSizeMake([TiUtils intValue:[self.proxy valueForKey:@"width"]],
                               [TiUtils intValue:[self.proxy valueForKey:@"height"]]);
    
    NSError *error = nil;
    self.recordingWriter = [[AVAssetWriter alloc] initWithURL:recordingUrl fileType:AVFileTypeQuickTimeMovie error:&error];
    
    if (error != nil)
    {
        NSLog(@"[ERROR] do not recording start");
        return;
    }

    NSDictionary *settings = @{AVVideoCodecKey: AVVideoCodecH264,
                               AVVideoWidthKey: [NSNumber numberWithInt:recordingSize.width],
                               AVVideoHeightKey: [NSNumber numberWithInt:recordingSize.height]};
    self.recordingInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    [self.recordingInput setExpectsMediaDataInRealTime:YES];
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, recordingSize.width * 0.5, recordingSize.height * 0.5);
    transform = CGAffineTransformRotate(transform , 90 / 180.0f * M_PI);
    transform = CGAffineTransformScale(transform, 1.0, 1.0);
    self.recordingInput.transform = transform;
    
    NSDictionary *bufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB)};
    self.recordingAdaptor = [AVAssetWriterInputPixelBufferAdaptor
                        assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.recordingInput
                        sourcePixelBufferAttributes:bufferAttributes];
    [self.recordingWriter addInput:self.recordingInput];
    [self.recordingWriter startWriting];
    [self.recordingWriter startSessionAtSourceTime:kCMTimeZero];
    
    isRecording = YES;
    
    if ([TiUtils boolValue:[args valueForKey:@"recordingSound"] def:YES])
    {
        AudioServicesPlaySystemSound(1117);
    }
#endif
}

-(void)stopRecording:(id)args
{
#ifndef __i386__
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
    ENSURE_UI_THREAD(stopRecording, args);

    successRecordingCallback = [args objectForKey:@"success"];
	ENSURE_TYPE_OR_NIL(successRecordingCallback, KrollCallback);
	[successRecordingCallback retain];
    
    errorRecordingCallback = [args objectForKey:@"error"];
	ENSURE_TYPE_OR_NIL(errorRecordingCallback, KrollCallback);
	[errorRecordingCallback retain];
    
    if (!isRecording)
    {
        NSLog(@"[WARN] video recording not start");
        if (errorRecordingCallback != nil)
        {
            id listener = [[errorRecordingCallback retain] autorelease];
            NSMutableDictionary *event = [TiUtils dictionaryWithCode:-1 message:@"video recording not start"];
            [NSThread detachNewThreadSelector:@selector(dispatchCallback:) toTarget:self withObject:[NSArray arrayWithObjects:@"error", event, listener, nil]];
        }
        return;
    }
    
    if ([TiUtils boolValue:[args valueForKey:@"recordingSound"] def:YES])
    {
        AudioServicesPlaySystemSound(1118);
    }
    
    dispatch_queue_t queue = dispatch_queue_create("be.k0suke.tilive.recordingQueue", NULL);
    
    [self.recordingInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        while ([self.recordingInput isReadyForMoreMediaData])
        {
            if ([self.recordingBuffer count] <= 1)
            {
                [self.recordingInput markAsFinished];
                [self.recordingWriter finishWritingWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([TiUtils boolValue:[args valueForKey:@"saveToPhotoGallery"] def:NO])
                        {
                            UISaveVideoAtPathToSavedPhotosAlbum([recordingUrl path], self, nil, nil);
                        }
                        
                        if (successRecordingCallback != nil)
                        {
                            id listener = [[successRecordingCallback retain] autorelease];
                            NSMutableDictionary *event = [TiUtils dictionaryWithCode:0 message:nil];
                            NSData *data = [NSData dataWithContentsOfURL:recordingUrl];
                            [event setObject:[[[TiBlob alloc] initWithData:data mimetype:@"video/quicktime"] autorelease] forKey:@"media"];
                            [NSThread detachNewThreadSelector:@selector(dispatchCallback:) toTarget:self withObject:[NSArray arrayWithObjects:@"success", event, listener, nil]];
                        }
                    });
                }];
                return;
            }
            
            CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[self.recordingBuffer objectAtIndex:0] CGImage] size:recordingSize];
            if (buffer)
            {
                if ([self.recordingAdaptor appendPixelBuffer:buffer
                                   withPresentationTime:CMTimeMake(recordingFrame, [TiUtils intValue:[self.proxy valueForKey:@"frameDuration"] def:16])])
                {
                    recordingFrame++;
                }
                else
                {
                    NSLog(@"[ERROR] recording write failed");
                }
                
                CFRelease(buffer);
                buffer = nil;
            }
            
            [self.recordingBuffer removeObjectAtIndex:0];
        }
    }];
    
    isRecording = NO;
#endif
}

-(void)startInterval:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
    ENSURE_UI_THREAD(startInterval, args);
    
    intervalSaveToPhotoGallery = [TiUtils boolValue:[args valueForKey:@"saveToPhotoGallery"] def:NO];
    intervalShutterSound = [TiUtils boolValue:[args valueForKey:@"shutterSound"] def:YES];
    
    NSNumber *delay = [NSNumber numberWithFloat:[[args objectForKey:@"intervalDelay"] intValue] / 1000];
    isInterval = NO;
    
    self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:[delay floatValue] target:self selector:@selector(intervalFlag:) userInfo:nil repeats:YES];
}

-(void)intervalFlag:(NSTimer*)timer
{
    isInterval = YES;
}

-(void)stopInterval:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
    ENSURE_UI_THREAD(stopInterval, args);

    [self.intervalTimer invalidate];
}

-(id)isFrontCamera:(id)args
{
#ifndef __i386__
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)
    {
        NSError *error = nil;
        
        AVCaptureDevicePosition position = [[self.videoInput device] position];
        if (position == AVCaptureDevicePositionFront)
        {
            return NUMBOOL(YES);
        }
    }
    
    return NUMBOOL(NO);
#endif
}

-(id)isBackCamera:(id)args
{
#ifndef __i386__
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)
    {
        NSError *error = nil;
        
        AVCaptureDevicePosition position = [[self.videoInput device] position];
        if (position == AVCaptureDevicePositionFront)
        {
            return NUMBOOL(NO);
        }
    }
    
    return NUMBOOL(YES);
#endif
}

-(id)isTorch:(id)args
{
#ifndef __i386__
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    if ([device hasTorch] == YES && device.torchMode == AVCaptureTorchModeOn)
    {
        return NUMBOOL(YES);
    }
    
    return NUMBOOL(NO);
#endif
}

-(void)toggleCamera:(id)args
{
#ifndef __i386__
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)
    {
        NSError *error = nil;
        
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[self.videoInput device] position];
        if (position == AVCaptureDevicePositionBack)
        {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self deviceWithPosition:AVCaptureDevicePositionFront] error:&error];
        }
        else
        {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self deviceWithPosition:AVCaptureDevicePositionBack] error:&error];
        }
        
        if (!newVideoInput)
        {
            NSLog(@"[ERROR] %@", error);
            return;
        }
        
        [self.videoSession beginConfiguration];
        [self.videoSession removeInput:self.videoInput];
        
        if ([self.videoSession canAddInput:newVideoInput])
        {
            [self.videoSession addInput:newVideoInput];
            self.videoInput = newVideoInput;
        }
        else
        {
            [self.videoSession addInput:self.videoInput];
        }
        
        [self.videoSession commitConfiguration];
    }
#endif
}

-(void)toggleTorch:(id)args
{
#ifndef __i386__
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)
    {
        NSError *error = nil;
        
        AVCaptureDevicePosition position = [[self.videoInput device] position];
        if (position == AVCaptureDevicePositionFront)
        {
            NSLog(@"[ERROR] do not support torch in front camera mode");
            return;
        }
    }

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    if (![device hasTorch])
    {
        NSLog(@"[ERROR] do not support torch in this device");
        return;
    }
    
    if (device.torchMode == AVCaptureTorchModeOff)
    {
        [device lockForConfiguration:&error];
        device.torchMode = AVCaptureTorchModeOn;
        [device unlockForConfiguration];
    }
    else
    {
        [device lockForConfiguration:&error];
        device.torchMode = AVCaptureTorchModeOff;
        [device unlockForConfiguration];
    }
#endif
}

#ifndef __i386__
-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(NULL, self.recordingAdaptor.pixelBufferPool, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4 * size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    UIGraphicsBeginImageContext(CGSizeMake(height, width));
    context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, -M_PI_2);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CGImageRelease(imageRef);
    
    return image;
}

-(UIImage *)imageCropping:(UIImage *)image rect:(CGRect)rect
{

}

-(void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    float scale = [[UIScreen mainScreen] scale];
    CGRect rect = CGRectMake((image.size.width - [TiUtils floatValue:[self.proxy valueForKey:@"width"]]) * scale / 2.0,
                             (image.size.height - [TiUtils floatValue:[self.proxy valueForKey:@"height"]]) * scale / 2.0,
                             [TiUtils floatValue:[self.proxy valueForKey:@"width"]] * scale,
                             [TiUtils floatValue:[self.proxy valueForKey:@"height"]] * scale);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    image = [UIImage imageWithCGImage:imageRef
                                scale:scale
                          orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    
    if (isSepia)
    {
        GPUImagePicture *imageSource = [[GPUImagePicture alloc] initWithImage:image smoothlyScaleOutput:NO];
        GPUImageSepiaFilter *imageFilter = [[GPUImageSepiaFilter alloc] init];
        [imageFilter prepareForImageCapture];
        [imageSource addTarget:imageFilter];
        [imageSource processImage];
        image = [imageFilter imageFromCurrentlyProcessedOutputWithOrientation:image.imageOrientation];
        [imageSource removeAllTargets];
        [imageFilter release];
        [imageSource release];
    }
    
    if (isInterval && [self.proxy _hasListeners:@"interval"])
	{
        isInterval = NO;
        
        if (intervalShutterSound)
        {
            AudioServicesPlaySystemSound(1108);
        }

        if (intervalSaveToPhotoGallery)
        {
            UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
        }
        
        NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [[[TiBlob alloc] initWithImage:image] autorelease], @"media",
                                    nil];
		[self.proxy fireEvent:@"interval" withObject:properties];
    }
    
    if (isRecording)
    {
        [self.recordingBuffer addObject:image];
        
        if ([self.recordingInput isReadyForMoreMediaData])
        {
            CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[self.recordingBuffer objectAtIndex:0] CGImage] size:recordingSize];
            
            if (buffer)
            {
                if ([self.recordingAdaptor appendPixelBuffer:buffer
                                   withPresentationTime:CMTimeMake(recordingFrame, [TiUtils intValue:[self.proxy valueForKey:@"frameDuration"] def:16])])
                {
                    recordingFrame++;
                }
                else
                {
                    NSLog(@"[ERROR] recording append failed");
                }
                
                CFRelease(buffer);
                buffer = nil;
            }
            
            [self.recordingBuffer removeObjectAtIndex:0];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.videoPreview.image = image;
    });
}

-(void)tapDetected:(UITapGestureRecognizer*)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:tapRecognizer.view];
    CGPoint pointOfInterest = CGPointMake(point.y / [TiUtils floatValue:[self.proxy valueForKey:@"height"]],
                                          1.0 - point.x / [TiUtils floatValue:[self.proxy valueForKey:@"width"]]);
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    if ([device lockForConfiguration:&error])
    {
        if ([device isFocusPointOfInterestSupported] &&
            [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
        {
            device.focusPointOfInterest = pointOfInterest;
            device.focusMode = AVCaptureFocusModeAutoFocus;
        }
        
        if ([device isExposurePointOfInterestSupported] &&
            [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        {
            adjustingExposure = YES;
            device.exposurePointOfInterest = pointOfInterest;
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        
        [device unlockForConfiguration];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (!adjustingExposure)
    {
        return;
    }
    
	if ([keyPath isEqual:@"adjustingExposure"])
    {
		if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == NO)
        {
            adjustingExposure = NO;
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            
			NSError *error = nil;
			if ([device lockForConfiguration:&error])
            {
				[device setExposureMode:AVCaptureExposureModeLocked];
				[device unlockForConfiguration];
			}
		}
	}
}
#endif

-(void)setSepia_:(id)args
{
    isSepia = [TiUtils boolValue:args def:NO];
}

@end
