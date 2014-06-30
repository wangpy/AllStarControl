//
//  SingleStringPlayingNode.m
//  AllStarControl
//
//  Created by Brian Wang on 1/1/13.
//
//

#import "SingleStringPlayingNode.h"
#import "HelloWorldLayer.h"

@interface SingleStringPlayingNode ()

@property (nonatomic, assign) CGPoint touchLocation;
@property (atomic, assign) BOOL isTouchedDown;

@end

@implementation SingleStringPlayingNode

@synthesize size;
@synthesize layer;
@synthesize stringIndex;
@synthesize touchLocation;
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
        ccDrawSolidRect(ccp(self.touchLocation.x - 60.0, self.touchLocation.y - 60.0),
                        ccp(self.touchLocation.x + 60.0, self.touchLocation.y + 60.0),
                        ccc4f(1.0, 1.0, 1.0, 0.8));
    }
}

- (void)panic
{
    self.isTouchedDown = NO;
    [self.layer sendNoteOfStringIndex:self.stringIndex touchVelocity:0 moving:NO];
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
    if (self.layer.isSweepMode) {
        return NO;
    }
    CGPoint location = [self convertTouchToNodeSpace: touch];
    if (location.x >= 0.0 && location.x < size.width
        && location.y >= 0.0 && location.y < size.height) {
        self.touchLocation = location;
        self.isTouchedDown = YES;
        UInt8 velocity = (UInt8)(127.0 * location.x / (size.width / 4.0));
        if (self.stringIndex >= 6) {
            // 6: 0,1,2
            // 7: 3,4,5
            int baseIndex = (self.stringIndex - 6) * 3;
            [self.layer sendNoteOfStringIndex:baseIndex touchVelocity:velocity moving:NO];
            [self.layer sendNoteOfStringIndex:baseIndex+1 touchVelocity:velocity moving:NO];
            [self.layer sendNoteOfStringIndex:baseIndex+2 touchVelocity:velocity moving:NO];
        } else {
            [self.layer sendNoteOfStringIndex:self.stringIndex touchVelocity:velocity moving:NO];
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint location = [self convertTouchToNodeSpace: touch];
    location.x = MIN(MAX(location.x, 0.0), size.width);
    //location.y = MIN(MAX(location.y, 0.0), size.height);
    self.touchLocation = location;
    if (location.y >= 0.0 && location.y < size.height) {
        UInt8 velocity = (UInt8)(127.0 * location.x / size.width);
        velocity = MIN(MAX(velocity, 1), 127);
        if (self.stringIndex >= 6) {
            // 6: 0,1,2
            // 7: 3,4,5
            int baseIndex = (self.stringIndex - 6) * 3;
            [self.layer sendNoteOfStringIndex:baseIndex touchVelocity:velocity moving:YES];
            [self.layer sendNoteOfStringIndex:baseIndex+1 touchVelocity:velocity moving:YES];
            [self.layer sendNoteOfStringIndex:baseIndex+2 touchVelocity:velocity moving:YES];
        } else {
            [self.layer sendNoteOfStringIndex:self.stringIndex touchVelocity:velocity moving:YES];
        }
    } else if (self.stringIndex >= 0 && self.stringIndex <= 6) {
        int stringIndexOffset = -1 * floorf(location.y / size.height); // index in reverse direction of y
        int newStringIndex = self.stringIndex + stringIndexOffset;
        newStringIndex = MIN(MAX(newStringIndex, 0), 5);
        UInt8 velocity = (UInt8)(127.0 * location.x / size.width);
        velocity = MIN(MAX(velocity, 1), 127);
        [self.layer sendNoteOfStringIndex:newStringIndex touchVelocity:velocity moving:NO];
    }
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    self.isTouchedDown = NO;
    CGPoint location = [self convertTouchToNodeSpace: touch];
    if (location.y >= 0.0 && location.y < size.height) {
        if (self.stringIndex >= 6) {
            // 6: 0,1,2
            // 7: 3,4,5
            int baseIndex = (self.stringIndex - 6) * 3;
            [self.layer sendNoteOfStringIndex:baseIndex touchVelocity:0 moving:NO];
            [self.layer sendNoteOfStringIndex:baseIndex+1 touchVelocity:0 moving:NO];
            [self.layer sendNoteOfStringIndex:baseIndex+2 touchVelocity:0 moving:NO];
        } else {
            [self.layer sendNoteOfStringIndex:self.stringIndex touchVelocity:0 moving:NO];
        }
    }
}

@end
