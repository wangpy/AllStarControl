//
//  HelloWorldLayer.m
//  AllStarControl
//
//  Created by Brian Wang on 12/29/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#include <CoreMotion/CoreMotion.h>


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#import "BackgroundNode.h"
#import "RibbonPitchBendNode.h"
#import "SingleStringPlayingNode.h"

#import "PGMidi.h"

#pragma mark - HelloWorldLayer

@interface HelloWorldLayer () <PGMidiDelegate, PGMidiSourceDelegate>

@property (nonatomic, retain) CMMotionManager *motionManager;
@property (nonatomic, retain) CMAttitude *referenceAttitude;
@property (nonatomic, retain) CMAttitude *currentAttitude;
@property (nonatomic, assign) CMAcceleration referenceGravityVector;
@property (nonatomic, assign) CMAcceleration currentGravityVector;
@property (nonatomic, retain) CCLabelTTF *centerLabel;
@property (nonatomic, retain) CCSprite *logoSprite;
@property (nonatomic, retain) BackgroundNode *backgroundNode;
@property (nonatomic, retain) RibbonPitchBendNode *pitchBendNode;
@property (nonatomic, retain) CCMenu *outputPortMenu;
@property (nonatomic, retain) NSMutableArray *sgpNodeArray;
@property (nonatomic, retain) NSMutableArray *touchArray;
@property (atomic, assign) int touchDownCount;
@property (atomic, assign) int octaveOffset;
@property (atomic, assign) int transposeOffset;
@property (atomic, assign) int updateCounter;
@property (atomic, assign) double currentRelativeDeviceAngle;
@property (atomic, assign) BOOL isSendingAngleModCC;

@end

const int baseNote[6] = { 64, 59, 55, 50, 45, 40 };
int activeNote[6] = { 64, 59, 55, 50, 45, 40 };
int sendingNote[6] = { 64, 59, 55, 50, 45, 40 };
int showingNote[6] = { 64, 59, 55, 50, 45, 40 };

// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize motionManager;
@synthesize referenceAttitude;
@synthesize currentAttitude;
@synthesize referenceGravityVector;
@synthesize currentGravityVector;
@synthesize midi = _midi;
@synthesize centerLabel;
@synthesize backgroundNode;
@synthesize pitchBendNode;
@synthesize outputPortMenu;
@synthesize sgpNodeArray;
@synthesize touchLocation;
@synthesize isTouchedDown;
@synthesize activeVelocity;
@synthesize activeModValue;
@synthesize touchArray;
@synthesize touchDownCount;
@synthesize octaveOffset;
@synthesize transposeOffset;
@synthesize updateCounter;
@synthesize currentRelativeDeviceAngle;
@synthesize isSendingAngleModCC;
@synthesize isSweepMode;

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {

        // ask director for the window size
        CGSize size = [[CCDirector sharedDirector] winSize];
		
        BackgroundNode *bgNode = [[BackgroundNode alloc] init];
        bgNode.position = CGPointZero;
        [self addChild:bgNode z:-2];
        bgNode.layer = self;
        self.backgroundNode = bgNode;
        
        self.logoSprite = [CCSprite spriteWithFile:@"bw_logo_transparent.png"];
        self.logoSprite.position =  ccp( size.height /2 , size.width /2 );
        self.logoSprite.opacity = 192;
        self.logoSprite.scale = 2.0;
        [self addChild:self.logoSprite z:-2];

        self.sgpNodeArray = [NSMutableArray arrayWithCapacity:6];
        for (int i=0; i<7; i++) {
            SingleStringPlayingNode *sgpNode = [[SingleStringPlayingNode alloc] init];
            sgpNode.position = ccp(size.height * 3.0 / 4.0, size.width * (i + 2) / 10.0);
            if (i <= 5) {
                sgpNode.size = CGSizeMake(size.height / 4.0, size.width / 10.0);
            } else {
                sgpNode.size = CGSizeMake(size.height / 4.0, size.width / 5.0);
            }
            [self addChild:sgpNode z:1];
            sgpNode.stringIndex = 5 - i; // last string on bottom, negative means mute all
            sgpNode.layer = self;
            [self.sgpNodeArray addObject:sgpNode];
        }
        for (int i=0; i<2; i++) {
            SingleStringPlayingNode *sgpNode = [[SingleStringPlayingNode alloc] init];
            sgpNode.position = ccp(size.height * 5.0 / 8.0, size.width * (3 * i + 2) / 10.0);
            sgpNode.size = CGSizeMake(size.height / 8.0, size.width * 3 / 10.0);
            [self addChild:sgpNode z:1];
            sgpNode.stringIndex = 7 - i; // 6: upper 3 strings, 7: lower 3 strings
            sgpNode.layer = self;
            [self.sgpNodeArray addObject:sgpNode];
        }
        
        RibbonPitchBendNode *pbNode = [[RibbonPitchBendNode alloc] init];
        pbNode.position = ccp(50, 50);
        pbNode.size = CGSizeMake(size.height - 100.0, 100.0);
        [self addChild:pbNode z:1];
        pbNode.layer = self;
        self.pitchBendNode = pbNode;

		// create and initialize a Label
        {
            CCLabelTTF *label = [CCLabelTTF labelWithString:@"Hello World" fontName:@"Marker Felt" fontSize:16];
            
            // position the label on the center of the screen
            label.position =  ccp( size.height /2 , size.width /2 );
            label.color = ccc3(255, 255, 255);
            // add the label as a child to this Layer
            [self addChild: label z:-1];
            self.centerLabel = label;
        }

        {
            CCLabelTTF *label = [CCLabelTTF labelWithString:@"Brian's Awesome Synth Guitar by BW Innovation" fontName:@"Marker Felt" fontSize:28];
            
            // position the label on the center of the screen
            label.position =  ccp( 300 , 170 );
            label.color = ccc3(255, 255, 255);
            // add the label as a child to this Layer
            [self addChild: label z:-1];
        }
        
        [CCMenuItemFont setFontSize:26];
        // Standard method to create a button
        CCMenuItem *panicMenuItem = [CCMenuItemFont itemWithString:@"Panic" target:self selector:@selector(panic:)];
        CCMenuItem *testMenuItem = [CCMenuItemFont itemWithString:@"Rand" target:self selector:@selector(test:)];
        CCMenuItem *octaveDownMenuItem = [CCMenuItemFont itemWithString:@"Oct-" block:^(id sender) {
            [self panic:nil];
            self.octaveOffset--;
            [self sendNotesWithTouchVelocity];
        }];
        CCMenuItem *octaveUpMenuItem = [CCMenuItemFont itemWithString:@"Oct+" block:^(id sender) {
            [self panic:nil];
            self.octaveOffset++;
            [self sendNotesWithTouchVelocity];
        }];
        CCMenuItem *transposeDownMenuItem = [CCMenuItemFont itemWithString:@"Trnsp-" block:^(id sender) {
            [self panic:nil];
            self.transposeOffset--;
            [self sendNotesWithTouchVelocity];
        }];
        CCMenuItem *transposeUpMenuItem = [CCMenuItemFont itemWithString:@"Trnsp+" block:^(id sender) {
            [self panic:nil];
            self.transposeOffset++;
            [self sendNotesWithTouchVelocity];
        }];
        CCMenuItem *calibGyroMenuItem = [CCMenuItemFont itemWithString:@"Calib" block:^(id sender) {
            self.referenceAttitude = self.motionManager.deviceMotion.attitude;
            self.referenceGravityVector = self.motionManager.deviceMotion.gravity;
        }];
        CCMenuItem *toggleGyroCCMenuItem = [CCMenuItemFont itemWithString:@"GyroCC" block:^(id sender) {
            self.isSendingAngleModCC = !self.isSendingAngleModCC;
        }];
        CCMenuItem *toggleSweepModeMenuItem = [CCMenuItemFont itemWithString:@"SweepMode" block:^(id sender) {
            self.isSweepMode = !self.isSweepMode;
            for (SingleStringPlayingNode *sgpNode in self.sgpNodeArray) {
                sgpNode.visible = !self.isSweepMode;
            }
        }];
        CCMenu *menu = [CCMenu menuWithItems:
                        panicMenuItem, testMenuItem,
                        octaveDownMenuItem, octaveUpMenuItem,
                        transposeDownMenuItem, transposeUpMenuItem,
                        calibGyroMenuItem, toggleGyroCCMenuItem, toggleSweepModeMenuItem,
                        nil];
		[menu alignItemsHorizontallyWithPadding:20];

		[menu setPosition:ccp( size.height * 0.75 / 2.0, size.width - 20)];
        [self addChild:menu];

        for (int i=0; i<6; i++) {
            activeNote[i] = baseNote[i];
            sendingNote[i] = baseNote[i];
            showingNote[i] = baseNote[i];
        }
        
        self.touchArray = [NSMutableArray arrayWithCapacity:5];
        self.touchDownCount = 0;
        
        self.midi = [[PGMidi alloc] init];
        [self.midi enableNetwork:YES];

        [self createOutputPortMenu];
        
        // Schedule Gyro updates
        self.motionManager = [[[CMMotionManager alloc] init] autorelease];
        self.referenceAttitude = nil;
        self.referenceGravityVector = self.motionManager.deviceMotion.gravity;
        motionManager.deviceMotionUpdateInterval = 1.0/60.0;
        if (motionManager.isDeviceMotionAvailable) {
            [motionManager startDeviceMotionUpdates];
        }
        self.isSendingAngleModCC = NO;

        [self scheduleUpdate];
    }
	return self;
}

- (void) update:(ccTime)delta {
    updateCounter = (updateCounter + 1) % 10;
    CMDeviceMotion *currentDeviceMotion = motionManager.deviceMotion;
    CMAttitude *newAttitude = currentDeviceMotion.attitude;
    if (self.referenceAttitude) {
        [newAttitude multiplyByInverseOfAttitude:self.referenceAttitude];
    }
    self.currentAttitude = newAttitude;
    self.currentGravityVector = currentDeviceMotion.gravity;
    double prod = self.currentGravityVector.x * self.referenceGravityVector.x
        + self.currentGravityVector.y * self.referenceGravityVector.y
        + self.currentGravityVector.z * self.referenceGravityVector.z;
    self.currentRelativeDeviceAngle = acos(prod);
    if (self.currentGravityVector.y < self.referenceGravityVector.y) {
        self.currentRelativeDeviceAngle *= -1.0;
    }

    CGFloat refAngle = acos(self.referenceGravityVector.x);
    if (self.referenceGravityVector.x < 0) {
        refAngle *= -1.0;
    }
    self.logoSprite.rotation = (self.currentRelativeDeviceAngle - refAngle) * 180.0 / M_PI + 90.0;

    if (0 == updateCounter && self.isSendingAngleModCC) {
        [self sendMIDICC:1 value:MIN(MAX(64 + (int)(63 * self.currentRelativeDeviceAngle), 0), 127)];
    }
    [self updateLabel];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

- (void)createOutputPortMenu
{
    if (self.outputPortMenu) {
        [self.outputPortMenu removeFromParentAndCleanup:YES];
        self.outputPortMenu = nil;
    }
    NSArray *outputMenuItems = [self getOutputMenuItems];
    CCMenu *outputMenu = [CCMenu menuWithArray:outputMenuItems];
    [outputMenuItems release];
    CGSize size = [[CCDirector sharedDirector] winSize];
    outputMenu.position =  ccp( size.height - 300 , 20 );
    [outputMenu alignItemsHorizontallyWithPadding:20];
    [self addChild:outputMenu];
    self.outputPortMenu = outputMenu;
}

- (NSArray *)getOutputMenuItems
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:3];
    for (int i=0; i<self.midi.destinations.count; i++) {
        PGMidiDestination *destination = [self.midi.destinations objectAtIndex:i];
        CCMenuItemFont *toggle = [CCMenuItemFont itemWithString:destination.name target:self selector:@selector(outputPortMenuItemClicked:)];
        toggle.tag = i;
        [result addObject:toggle];
    }
    return [result retain];
}

- (void)outputPortMenuItemClicked:(id)sender
{
    CCMenuItemFont *toggle = (CCMenuItemFont *)sender;
    for (int i=0; i<self.midi.destinations.count; i++) {
        PGMidiDestination *destination = [self.midi.destinations objectAtIndex:i];
        if (i == toggle.tag) {
            destination.isEnabledForSending = YES;
        } else {
            destination.isEnabledForSending = NO;
        }
    }
}

- (void) sendNotesWithTouchVelocity
{
    [self sendNotesWithTouchVelocityWithMoving:NO];
}

- (void) sendNotesWithTouchVelocityWithMoving:(BOOL)isMoving
{
    UInt8 x = (UInt8)floor( 127.0 * (MIN(MAX(self.touchLocation.x, 50.0), 590.0) - 50.0) / 540.0);
    UInt8 y = (UInt8)floor( 127.0 * (MIN(MAX(self.touchLocation.y, 768.0*0.25), 768.0*0.75) - 768.0*0.25) / (768.0 * 0.5));
    UInt8 velocity = x;
    UInt8 modValue = y;
    if (YES == self.isSweepMode) {
        velocity = y;
        modValue = y;
    }
    if (NO == self.isTouchedDown) {
        velocity = 0;
    }
    self.activeVelocity = velocity;
    for (int i=0; i<6; i++) {
        [self sendNoteOfStringIndex:i touchVelocity:velocity moving:isMoving];
    }
    
    self.activeModValue = modValue;
    [self sendMIDICC:7 value:modValue];
}

- (void) sendNoteOfStringIndex:(int)index touchVelocity:(int)velocity moving:(BOOL)isMoving
{
    if (index < 0) {
        for (int i=0; i<6; i++) {
            [self sendMIDInote:sendingNote[i] velocity:0 isOn:NO toChannel:15];
        }
        return;
    }
    
    int sendingNoteNum = sendingNote[index];
    int activeNoteNum = activeNote[index];
    int baseNoteNum = baseNote[index];
    
    if (YES == self.isSweepMode && activeNoteNum != baseNoteNum) {
        int pressedNoteNum = 0;
        for (int j=0; j<6; j++) {
            if (activeNote[j] > baseNote[j]) {
                pressedNoteNum++;
            }
        }
        if (0 == pressedNoteNum) {
            pressedNoteNum = 1;
        }
        
        UInt8 x = (UInt8)floor( 127.0 * (MIN(MAX(self.touchLocation.x, 50.0), 1024.0) - 50.0) / 1024.0);
        UInt8 zoneIndex = (UInt8)floor(((float)x/128.0) * 18.0);
        UInt8 shiftOctaveOffset = zoneIndex / pressedNoteNum;
        UInt8 sweepStringIndex = zoneIndex % pressedNoteNum;
        UInt8 sweepStringRealIndex = 6;
        UInt8 counter = 0;
        for (int j=5; j>=0; j--) {
            if (activeNote[j] == baseNote[j]) {
                continue;
            }
            sweepStringRealIndex = j;
            if (counter >= sweepStringIndex) {
                break;
            }
            counter++;
        }
        if (index > sweepStringRealIndex) {
            shiftOctaveOffset++;
        }
        if (index != sweepStringRealIndex) {
            velocity = 0;
        }
        activeNoteNum += 12 * shiftOctaveOffset;
        NSLog(@"Sweep:  index=%d zoneIndex=%d shiftOctaveOffset=%d sweepStringIndex=%d activeNoteNum=%d velocity=%d",
              index, zoneIndex, shiftOctaveOffset, sweepStringRealIndex, activeNoteNum, velocity);
    }

    if (0 == velocity) {
        [self sendMIDInote:sendingNoteNum velocity:0 isOn:NO toChannel:15];
        [self sendMIDInote:activeNoteNum velocity:0 isOn:NO toChannel:15];
        return;
    }
    
    BOOL noteChanged = NO;
    if (sendingNoteNum != activeNoteNum) {
        BOOL stillActive = NO;
        for (int j=0; j<6; j++) {
            if (sendingNoteNum == activeNote[j] // same note with any other string
                && activeNote[j] > baseNote[j]) { // other string is pressed
                stillActive = YES;
                break;
            }
        }
        if (NO == stillActive) {
            [self sendMIDInote:sendingNoteNum velocity:0 isOn:NO toChannel:15];
        }
        sendingNote[index] = sendingNoteNum = activeNoteNum;
        noteChanged = YES;
    }
    if ((sendingNoteNum > baseNoteNum)
        ) {
        BOOL isAftertouch = (NO == noteChanged && YES == isMoving) ? YES : NO;
        [self sendMIDInote:sendingNoteNum velocity:velocity isOn:YES toChannel:15 isAftertouch:isAftertouch];
    }
}

- (void) showNotesOnFretboard
{
    return; // disabled temporary
    
    for (int i=0; i<6; i++) {
        if (showingNote[i] != activeNote[i]) {
            [self fretboardNote:sendingNote[i] setShow:NO];
            showingNote[i] = activeNote[i];
        }
        if (showingNote[i] > baseNote[i]) {
            [self fretboardNote:sendingNote[i] setShow:YES];
        }
    }
}

- (void) fretboardNote:(UInt8)noteNum setShow:(BOOL)toShow
{
    for (int i=0; i<6; i++) {
        for (int j=activeNote[i]-24; j<=activeNote[i]+24; j+=12) {
            if (noteNum == j // same note with any other string
                && j > baseNote[i]) { // other string is pressed
                continue;
            }
            [self sendMIDInote:j velocity:((toShow) ? 127 : 0) isOn:toShow toChannel:i];
        }
    }
}

- (void) processNote:(UInt8)noteNum toOn:(BOOL)toOn channel:(UInt8)channel
{
    if (channel >= 6) {
        return;
    }
    if (NO == toOn) {
        activeNote[channel] = baseNote[channel];
    } else {
        activeNote[channel] = noteNum;
    }
    [self sendNotesWithTouchVelocity];
}

- (NSString *)noteNumOfStringIndex:(int)stringIndex
{
    if (activeNote[stringIndex] == baseNote[stringIndex]) {
        return @"--";
    } else {
        return [NSString stringWithFormat:@"%d", activeNote[stringIndex]];
    }
}

- (void) updateLabel
{
    NSString *activeNotesStr = [NSString stringWithFormat:@"| %@ %@ %@ %@ %@ %@ | Octave:%d Transp:%d | touch:%d | vel:%d mod:%d |\n| gx:%.6f gy:%.6f gz:%.6f | angle:%.6f sendCC:%d |",
                                [self noteNumOfStringIndex:0],
                                [self noteNumOfStringIndex:1],
                                [self noteNumOfStringIndex:2],
                                [self noteNumOfStringIndex:3],
                                [self noteNumOfStringIndex:4],
                                [self noteNumOfStringIndex:5],
                                self.octaveOffset, self.transposeOffset,
                                self.touchDownCount,
                                (self.isTouchedDown) ? self.activeVelocity : -1,
                                (self.isTouchedDown) ? self.activeModValue : -1,
                                currentGravityVector.x, currentGravityVector.y, currentGravityVector.z,
                                currentRelativeDeviceAngle, self.isSendingAngleModCC
                                ];
    self.centerLabel.string = activeNotesStr;
}

- (void)setPitchBend:(float)pitchBendValue
{
    NSLog(@"pitch bend:%f", pitchBendValue);
    int pbValue = 8192 + (int)(8191.0 * pitchBendValue);
    [self sendMIDIPBValue:pbValue];
}

- (void)panic:(id)sender
{
    for (SingleStringPlayingNode *sgpNode in self.sgpNodeArray) {
        [sgpNode panic];
    }
    for (int i=0; i<127; i++) {
        [self sendMIDInote:i velocity:0 isOn:NO toChannel:15];
    }
    [self.touchArray removeAllObjects];
    self.touchDownCount = 0;
    self.isTouchedDown = NO;
    [self sendMIDIPBValue:8192];
}

- (void)test:(id)sender
{
    int testNotes[4][6] = {
        67, 64, 59, 55, 48, 40,
        69, 64, 60, 55, 45, 45,
        69, 64, 60, 53, 45, 40,
        67, 62, 55, 50, 45, 43
    };
    int testNoteSetIndex = rand() % 4;
    for (int i=0; i<6; i++) {
        [self processNote:testNotes[testNoteSetIndex][i] toOn:YES channel:i];
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
    CGSize size = [[CCDirector sharedDirector] winSize];
    CGPoint location = [self convertTouchToNodeSpace: touch];
    if (location.x < 0.0 || location.x >= ((self.isSweepMode) ? size.width : (size.width * 0.625))
        || location.y < 50.0 || location.y >= (size.height - 50.0)) {
        return NO;
    }
    self.touchLocation = location;
    self.isTouchedDown = YES;
    [self.touchArray addObject:touch];
    self.touchDownCount++;
    [self sendNotesWithTouchVelocity];
    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    if (touch != [self.touchArray lastObject]) {
        return;
    }
    CGPoint location = [self convertTouchToNodeSpace: touch];
    self.touchLocation = location;
    [self sendNotesWithTouchVelocityWithMoving:YES];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    [self.touchArray removeObject:touch];
    if (--self.touchDownCount <= 0) {
        //self.touchLocation = CGPointMake(-1, -1);
        self.isTouchedDown = NO;
        self.touchDownCount = 0;
        [self sendNotesWithTouchVelocity];
    } else {
        self.touchLocation = [self convertTouchToNodeSpace:[self.touchArray lastObject]];
    }
}

#pragma - midi

const char *BoolToString(BOOL b) { return b ? "yes":"no"; }

NSString *ToString(PGMidiConnection *connection)
{
    return [NSString stringWithFormat:@"< PGMidiConnection: name=%@ isNetwork=%s >",
            connection.name, BoolToString(connection.isNetworkSession)];
}

- (void) attachToAllExistingSources
{
    for (PGMidiSource *source in _midi.sources)
    {
        source.delegate = self;
    }
}

- (void) setMidi:(PGMidi*)m
{
    _midi.delegate = nil;
    _midi = m;
    _midi.delegate = self;
    
    [self attachToAllExistingSources];
}

- (void) addString:(NSString*)string
{
    NSLog(@"MIDI: %@", string);
}

- (void) midi:(PGMidi*)midi sourceAdded:(PGMidiSource *)source
{
    source.delegate = self;
    [self addString:[NSString stringWithFormat:@"Source added: %@", ToString(source)]];
}

- (void) midi:(PGMidi*)midi sourceRemoved:(PGMidiSource *)source
{
    [self addString:[NSString stringWithFormat:@"Source removed: %@", ToString(source)]];
}

- (void) midi:(PGMidi*)midi destinationAdded:(PGMidiDestination *)destination
{
    [self addString:[NSString stringWithFormat:@"Desintation added: %@", ToString(destination)]];
    destination.isEnabledForSending = NO;
    [self createOutputPortMenu];
}

- (void) midi:(PGMidi*)midi destinationRemoved:(PGMidiDestination *)destination
{
    [self addString:[NSString stringWithFormat:@"Desintation removed: %@", ToString(destination)]];
    [self createOutputPortMenu];
}

NSString *StringFromPacket(const MIDIPacket *packet)
{
    // Note - this is not an example of MIDI parsing. I'm just dumping
    // some bytes for diagnostics.
    // See comments in PGMidiSourceDelegate for an example of how to
    // interpret the MIDIPacket structure.
    return [NSString stringWithFormat:@"  %u bytes: [%02x,%02x,%02x]",
            packet->length,
            (packet->length > 0) ? packet->data[0] : 0,
            (packet->length > 1) ? packet->data[1] : 0,
            (packet->length > 2) ? packet->data[2] : 0
            ];
}

- (void) receivedMIDI:(NSNumber *)inPacketRef {
    const MIDIPacket *inPacket = (const MIDIPacket *)[inPacketRef intValue];
    int length = inPacket->length;
    NSLog(@"package length = %d", length);
    if (!inPacket || 0 == length) {
        return;
    }
    int index=0;
    while (index < length) {
        UInt8 byte1 = inPacket->data[index];
        NSLog(@"status = 0x%x", byte1);
        if ((byte1 >= 0x80 && byte1 <= 0x8F) && (length-index) > 2) {
            UInt8 channel = byte1 & 0x0F;
            UInt8 noteNum = inPacket->data[index+1];
            UInt8 velocity = inPacket->data[index+2];
            NSLog(@"Channel=%d Received noteOff=%d velocity=%d", channel, noteNum, velocity);
            [self processNote:noteNum toOn:NO channel:channel];
            if (channel < 6) {
                [self showNotesOnFretboard];
            }

            index += 3;
        } else if ((byte1 >= 0x90 && byte1 <= 0x9F) && (length-index) > 2) {
            UInt8 channel = byte1 & 0x0F;
            UInt8 noteNum = inPacket->data[index+1];
            UInt8 velocity = inPacket->data[index+2];
            NSLog(@"Channel=%d Received noteOn=%d velocity=%d", channel, noteNum, velocity);
            [self processNote:noteNum toOn:YES channel:channel];
            if (channel < 6) {
                [self showNotesOnFretboard];
            }

            index += 3;
        } else if (
                   (byte1 >= 0xB0 && byte1 <= 0xBF) // control change
                   ) {
            UInt8 ccNum = inPacket->data[index+1];
            UInt8 value = inPacket->data[index+2];
            NSLog(@"Received CC=%d value=%d", ccNum, value);
                    
            index += 3;
        } else if (
                   (byte1 >= 0xC0 && byte1 <= 0xCF) // program change
                   ) {
            UInt8 program = inPacket->data[index+1];
            NSLog(@"Received PC=%d", program);
            
            
            index += 2;
        } else if (
                   (byte1 >= 0xA0 && byte1 <= 0xAF) // key pressure
                   || (byte1 >= 0xE0 && byte1 <= 0xEF) // pitch bend
                   || byte1 == 0xF2 // song position
                   ) {
            index += 3;
        } else if (
                   (byte1 >= 0xD0 && byte1 <= 0xDF) // channel pressure
                   || byte1 == 0xF3 // song select
                   || byte1 == 0xF5 // unofficial bus select
                   ) {
            index += 2;
        } else if (byte1 == 0xF0) { // sysex start
            do {
                index++;
            } while (inPacket->data[index] != 0xF7);
        } else {
            index++;
        }
    }
}

- (void) midiSource:(PGMidiSource*)midi midiReceived:(const MIDIPacketList *)packetList
{
    const MIDIPacket *packet = &packetList->packet[0];
    for (int i = 0; i < packetList->numPackets; ++i)
    {
        [self performSelectorOnMainThread:@selector(receivedMIDI:)
                               withObject:[NSNumber numberWithInt:(int)packet] // send pointer as NSNumber..
                            waitUntilDone:YES];
        packet = MIDIPacketNext(packet);
    }
}

- (void) sendMIDINoteInBackground:(NSDictionary *)arg {
    UInt8 channel = [(NSNumber *)[arg objectForKey:@"channel"] intValue] & 0x0F;
    BOOL isOn = [(NSNumber *)[arg objectForKey:@"isOn"] boolValue];
    UInt8 noteNum = [(NSNumber *)[arg objectForKey:@"noteNum"] intValue];
    UInt8 velocity = [(NSNumber *)[arg objectForKey:@"velocity"] intValue];
    BOOL isAftertouch = [(NSNumber *)[arg objectForKey:@"isAftertouch"] boolValue];
    
    UInt8 firstByte = ((isOn) ? ((isAftertouch) ? 0xa0 : 0x90) : 0x80) + channel;
    const UInt8 noteData[]  = { firstByte, noteNum, velocity};
    
    [_midi sendBytes:noteData size:sizeof(noteData)];
}

- (void) sendMIDInote:(int)inNoteNum velocity:(UInt8)velocity isOn:(BOOL)isOn toChannel:(int)channel {
    [self sendMIDInote:inNoteNum velocity:velocity isOn:isOn toChannel:channel isAftertouch:NO];
}

- (void) sendMIDInote:(int)inNoteNum velocity:(UInt8)velocity isOn:(BOOL)isOn toChannel:(int)channel isAftertouch:(BOOL)isAftertouch {
    int noteNum = inNoteNum + 12 * octaveOffset + transposeOffset;
    if (noteNum > 127 || noteNum < 0 || channel < 0 || channel > 15) {
        return;
    }
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:(channel & 0x0F)], @"channel",
                          [NSNumber numberWithBool:isOn], @"isOn",
                          [NSNumber numberWithBool:isAftertouch], @"isAftertouch",
                          [NSNumber numberWithInt:noteNum], @"noteNum",
                          [NSNumber numberWithInt:velocity], @"velocity", nil];
    
    [self performSelectorInBackground:@selector(sendMIDINoteInBackground:) withObject:data];
}

- (void) sendMIDICCInBackground:(NSDictionary *)arg {
    UInt8 ccNum = [(NSNumber *)[arg objectForKey:@"cc"] intValue];
    UInt8 value = [(NSNumber *)[arg objectForKey:@"value"] intValue];
    
    const UInt8 ccData[]  = { 0xBF, ccNum, value};
    
    [_midi sendBytes:ccData size:sizeof(ccData)];
}

- (void) sendMIDICC:(UInt8)ccNum value:(UInt8)value {
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:ccNum], @"cc",
                          [NSNumber numberWithInt:value], @"value", nil];
    
    [self performSelectorInBackground:@selector(sendMIDICCInBackground:) withObject:data];
}

- (void) sendMIDIPBInBackground:(NSDictionary *)arg {
    int value = [(NSNumber *)[arg objectForKey:@"value"] intValue];
    UInt8 lsb = value % 128;
    UInt8 msb = value / 128;
    const UInt8 ccData[]  = { 0xEF, lsb, msb};
    
    [_midi sendBytes:ccData size:sizeof(ccData)];
}

- (void) sendMIDIPBValue:(int)value {
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:value], @"value", nil];
    
    [self performSelectorInBackground:@selector(sendMIDIPBInBackground:) withObject:data];
}

@end
