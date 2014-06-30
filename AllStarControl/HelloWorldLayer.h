//
//  HelloWorldLayer.h
//  AllStarControl
//
//  Created by Brian Wang on 12/29/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

@class PGMidi;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <CCTargetedTouchDelegate>
{
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@property (nonatomic,strong) PGMidi *midi;

@property (nonatomic, assign) CGPoint touchLocation;
@property (atomic, assign) BOOL isTouchedDown;
@property (nonatomic, assign) int activeVelocity;
@property (nonatomic, assign) int activeModValue;
@property (atomic, assign) BOOL isSweepMode;

- (void)setPitchBend:(float)pitchBendValue;
- (void)sendNoteOfStringIndex:(int)index touchVelocity:(int)velocity moving:(BOOL)isMoving;

@end
