//
//  RibbonPitchBendNode.h
//  AllStarControl
//
//  Created by Brian Wang on 12/29/12.
//
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

@class HelloWorldLayer;

@interface RibbonPitchBendNode : CCNode <CCTargetedTouchDelegate>

@property (nonatomic, assign) CGSize size;
@property (nonatomic, retain) HelloWorldLayer *layer;

@end
