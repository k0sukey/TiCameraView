/**
 * BeK0sukeTicameraViewProxy.h
 */

#import "TiViewProxy.h"

@interface BeK0sukeTicameraViewProxy : TiViewProxy {

}

-(void)toggleCamera:(id)args;
-(void)takePicture:(id)args;
-(void)startRecording:(id)args;
-(void)stopRecording:(id)args;

@end
