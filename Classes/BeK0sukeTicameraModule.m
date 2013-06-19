/**
 * BeK0sukeTicameraModule.m
 */

#import "BeK0sukeTicameraModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation BeK0sukeTicameraModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"6f5e772c-e468-4464-af5c-f1e5a135476d";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"be.k0suke.ticamera";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
	
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added 
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma Public APIs

-(id)example:(id)args
{
	// example method
	return @"hello world";
}

-(id)exampleProp
{
	// example property getter
	return @"hello world";
}

-(void)setExampleProp:(id)value
{
	// example property setter
}

-(BOOL)hasFrontCamera:(id)args
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == AVCaptureDevicePositionFront)
        {
            return YES;
        }
    }
    return NO;
}

-(BOOL)hasBackCamera:(id)args
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == AVCaptureDevicePositionBack)
        {
            return YES;
        }
    }
    return NO;
}

MAKE_SYSTEM_PROP(CAMERA_FRONT, AVCaptureDevicePositionFront);
MAKE_SYSTEM_PROP(CAMERA_BACK, AVCaptureDevicePositionBack);

MAKE_SYSTEM_PROP(QUALITY_PHOTO, AVCaptureSessionPresetPhoto);
MAKE_SYSTEM_PROP(QUALITY_HIGH, AVCaptureSessionPresetHigh);
MAKE_SYSTEM_PROP(QUALITY_MEDIUM, AVCaptureSessionPresetMedium);
MAKE_SYSTEM_PROP(QUALITY_LOW, AVCaptureSessionPresetLow);
MAKE_SYSTEM_PROP(QUALITY_640x480, AVCaptureSessionPreset640x480);
MAKE_SYSTEM_PROP(QUALITY_1280x720, AVCaptureSessionPreset1280x720);

@end
