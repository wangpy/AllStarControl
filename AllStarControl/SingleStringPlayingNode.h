//
//  SingleStringPlayingNode.h
//  AllStarControl
//
//  Created by Brian Wang on 1/1/13.
//
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

@class HelloWorldLayer;

@interface SingleStringPlayingNode : CCNode <CCTargetedTouchDelegate>

@property (nonatomic, assign) CGSize size;
@property (nonatomic, retain) HelloWorldLayer *layer;
@property (nonatomic, assign) int stringIndex;

- (void)panic;

@end
