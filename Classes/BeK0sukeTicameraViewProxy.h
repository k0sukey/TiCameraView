/**
 * BeK0sukeTicameraViewProxy.h
 */

#import "TiViewProxy.h"

@interface BeK0sukeTicameraViewProxy : TiViewProxy {

}

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
