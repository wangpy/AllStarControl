//
//  RibbonPitchBendNode.m
//  AllStarControl
//
//  Created by Brian Wang on 12/29/12.
//
//

#import "RibbonPitchBendNode.h"
#import "HelloWorldLayer.h"

@interface RibbonPitchBendNode ()

@property (nonatomic, assign) CGPoint touchStartLocation;
@property (nonatomic, assign) CGPoint touchMoveLocation;
@property (atomic, assign) BOOL isTouchedDown;

@end

@implementation RibbonPitchBendNode

@synthesize size;
@synthesize layer;
@synthesize touchStartLocation;
@synthesize touchMoveLocation;
@synthesize isTouchedDown;

// This is CCNode's draw method
-(void) draw
{
    // override me
    // Only use this function to draw your stuff.
    // DON'T draw your stuff outside this method
    glColor4ub(128, 128, 128, 255);
    ccDrawRect(ccp(0, 0), ccp(size.width, size.height));
    if (self.isTouchedDown) {
        glColor4ub(255, 255, 255, 0);
        ccDrawSolidRect(ccp(self.touchStartLocation.x - 30.0, self.touchStartLocation.y - 30.0),
                        ccp(self.touchStartLocation.x + 30.0, self.touchStartLocation.y + 30.0),
                        ccc4f(1.0, 1.0, 1.0, 0.8));
        ccDrawSolidRect(ccp(self.touchMoveLocation.x - 40.0, self.touchMoveLocation.y - 40.0),
                        ccp(self.touchMoveLocation.x + 40.0, self.touchMoveLocation.y + 40.0),
                        ccc4f(1.0, 1.0, 1.0, 0.6));
    }
}

#pragma - touch

- (void)onEnter
{
	[[[CCDirectorIOS sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
	[super onEnter];
}

- (void)onExit
{
	[[[CCDirectorIOS sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.isTouchedDown) {
        return NO;
    }
    CGPoint location = [self convertTouchToNodeSpace: touch];
    CGFloat handlePosition = size.height / 2.0;
    if (location.x >= handlePosition && location.x < (size.width - handlePosition)
        && location.y >= 0.0 && location.y <= size.height) {
        location.y = handlePosition;
        self.touchStartLocation = location;
        self.touchMoveLocation = location;
        self.isTouchedDown = YES;
        return YES;
    } else {
        return NO;
    }
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint location = [self convertTouchToNodeSpace: touch];
    
    CGFloat handlePosition = size.height / 2.0;
    location.y = handlePosition;
    self.touchMoveLocation = location;
    CGFloat maxDistance = size.width / 2.0;
    CGFloat pbValue = (location.x - self.touchStartLocation.x) / maxDistance;
    if (pbValue < -1.0) {
        pbValue = -1.0;
    } else if (pbValue > 1.0) {
        pbValue = 1.0;
    }
    [self.layer setPitchBend:pbValue];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    self.isTouchedDown = NO;
    [self.layer setPitchBend:0.0];
}

@end
