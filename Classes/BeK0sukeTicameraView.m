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

#ifndef __i386__
-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
/*    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height,
                                          kCVPixelFormatType_32ARGB, (CFDictionaryRef) options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height,
                                                 8, 4 * size.width, rgbColorSpace, kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;*/
    
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
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                    width,
                                                    height,
                                                    8,
                                                    bytesPerRow,
                                                    colorSpace,
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
    
    CGImageRelease(cgImage);
    
    return image;
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.videoPreview.image = image;
    });
    
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
}
#endif

@end
