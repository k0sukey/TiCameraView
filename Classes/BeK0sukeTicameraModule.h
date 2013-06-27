/**
 * BeK0sukeTicameraModule.h
 */

#import "TiModule.h"
#import <AVFoundation/AVFoundation.h>

@interface BeK0sukeTicameraModule : TiModule 
{
}

-(id)hasFrontCamera:(id)args;
-(id)hasBackCamera:(id)args;
-(id)hasTorch:(id)args;

@property (nonatomic, readonly) NSNumber *CAMERA_FRONT;
@property (nonatomic, readonly) NSNumber *CAMERA_BACK;

@property (nonatomic, readonly) NSNumber *QUALITY_PHOTO;
@property (nonatomic, readonly) NSNumber *QUALITY_HIGH;
@property (nonatomic, readonly) NSNumber *QUALITY_MEDIUM;
@property (nonatomic, readonly) NSNumber *QUALITY_LOW;
@property (nonatomic, readonly) NSNumber *QUALITY_640x480;
@property (nonatomic, readonly) NSNumber *QUALITY_1280x720;

@end
