//
//  BackgroundNode.m
//  AllStarControl
//
//  Created by Brian Wang on 12/29/12.
//
//

#import "BackgroundNode.h"
#import "HelloWorldLayer.h"

@interface BackgroundNode ()

@property (nonatomic, retain) CCSprite *bgTextureSprite;
@end

@implementation BackgroundNode

@synthesize layer;
@synthesize bgTextureSprite;

- (id) init
{
    self = [super init];
    if (self) {
        self.bgTextureSprite = [CCSprite spriteWithFile:@"texture.jpg"];
        CGSize size = [[CCDirector sharedDirector] winSize];
        self.bgTextureSprite.position = ccp(size.height / 2.0, size.width / 2.0);
        [self addChild:self.bgTextureSprite z:-1];
    }
    
    return self;
}

// This is CCNode's draw method
-(void) draw
{
    // override me
    // Only use this function to draw your stuff.
    // DON'T draw your stuff outside this method
    CGSize size = [[CCDirector sharedDirector] winSize];
    ccColor4F color = ccc4f(
                            self.layer.activeVelocity * (float)self.layer.isTouchedDown / 127.0,
                            self.layer.activeModValue * (float)self.layer.isTouchedDown * 0.5 / 127.0,
                            0.0,
                            (self.layer.isTouchedDown) ? 0.75 : 0.0);
    ccDrawSolidRect(ccp(0, 0), ccp(size.width, size.height), color);
    
    if (self.layer.isTouchedDown) {
        ccDrawSolidRect(ccp(self.layer.touchLocation.x-100.0, self.layer.touchLocation.y-100.0),
                        ccp(self.layer.touchLocation.x+100.0, self.layer.touchLocation.y+100.0),
                        ccc4f(1.0, 1.0, 1.0, 0.4));
    }
}

@end
