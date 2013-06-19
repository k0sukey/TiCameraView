/**
 * BeK0sukeTicameraViewProxy.m
 */

#import "BeK0sukeTicameraViewProxy.h"
#import "BeK0sukeTicameraView.h"
#import "TiUtils.h"

@implementation BeK0sukeTicameraViewProxy

#ifndef USE_VIEW_FOR_UI_METHOD
#define USE_VIEW_FOR_UI_METHOD(methodname)\
-(void)methodname:(id)args\
{\
[self makeViewPerformSelector:@selector(methodname:) withObject:args createIfNeeded:YES waitUntilDone:NO];\
}
#endif

USE_VIEW_FOR_UI_METHOD(toggleCamera);
USE_VIEW_FOR_UI_METHOD(takePicture);
USE_VIEW_FOR_UI_METHOD(startRecording);
USE_VIEW_FOR_UI_METHOD(stopRecording);

@end
