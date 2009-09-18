//
//  LogicEngine.m
//  TapMania
//
//  Created by Alex Kremer on 01.12.08.
//  Copyright 2008 Godexsoft. All rights reserved.
//

#import "TapMania.h"

#import "FadeTransition.h"
#import "SongsDirectoryCache.h"
#import "TMSoundEngine.h"
#import "InputEngine.h"
#import "SettingsEngine.h"
#import "ThemeManager.h"
#import "NewsFetcher.h"
#import "EAGLView.h"
#import "ARRollerView.h"
#import "MessageManager.h"
#import "TMMessage.h"
#import "TMScreen.h"
#import "TMModalView.h"

#import "TMRunLoop.h"	// TMRunLoopPriority
#import "JoyPad.h"
#import "SongsCacheLoaderRenderer.h"

#import "GameState.h"
#import "FPS.h"

TMGameState* g_pGameState;

// This is a singleton class, see below
static TapMania *sharedTapManiaDelegate = nil;

@implementation TapMania

@synthesize m_pGlView, m_pWindow, m_pJoyPad, m_pGameRunLoop;

- (id) init {
	self = [super init];
	if(!self)
		return nil;

	// Start the message manager and register some basic messages
	REG_MESSAGE(kApplicationStartedMessage, [@"ApplicationStarted" retain]);
	REG_MESSAGE(kApplicationShouldTerminateMessage, [@"ApplicationShouldTerminate" retain]);
	
	// Load up user configuration and cache
	[[SettingsEngine sharedInstance] loadUserConfig];
	
	// Defaults
	m_pCurrentSong = nil;
	m_pCurrentSongOptions = nil;
	m_pCurrentScreen = nil;
	
	g_pGameState = (TMGameState*)malloc(sizeof(TMGameState));
	
	return self;
}

- (void) switchToScreen:(TMScreen*)screenRenderer {
	[self registerObjectAtBegin:[[FadeTransition alloc] initFromScreen:m_pCurrentScreen toScreen:screenRenderer]];
}

- (void) switchToScreen:(TMScreen*)screenRenderer usingTransition:(Class)transitionClass {
	[self registerObjectAtBegin:[[transitionClass alloc] initFromScreen:m_pCurrentScreen toScreen:screenRenderer]];
}

- (void) switchToScreen:(TMScreen*)screenRenderer usingTransition:(Class)transitionClass timeIn:(double)timeIn timeOut:(double) timeOut {
	[self registerObjectAtBegin:[[transitionClass alloc] initFromScreen:m_pCurrentScreen toScreen:screenRenderer timeIn:timeIn timeOut:timeOut]];
}

- (void) addOverlay:(TMModalView*)modalView {
	[self registerObjectAtEnd:modalView];
}

- (void) removeOverlay:(TMModalView*)modalView {
	[self deregisterObject:modalView];
	[modalView release];
}

- (void) registerObjectAtEnd:(NSObject*) obj {
	[m_pGameRunLoop pushBackChild:obj];
}

- (void) registerObjectAtBegin:(NSObject*) obj {
	[m_pGameRunLoop pushChild:obj];
}

- (void) deregisterObject:(NSObject*) obj {
	[m_pGameRunLoop removeObject:obj];
}

- (void) deregisterAll {
	[m_pGameRunLoop removeAllObjects];
}

- (void) setCurrentScreen:(NSObject*)screenRenderer {
	m_pCurrentScreen = screenRenderer;
}

- (void) releaseCurrentScreen {
	if(m_pCurrentScreen != nil){
		[m_pCurrentScreen release];
	}
}

- (void) startGame {
	// Alloc main run loop
	m_pGameRunLoop = [[TMRunLoop alloc] init];
	[m_pGameRunLoop delegate:self];	

	// And run it
	[m_pGameRunLoop performSelectorOnMainThread:@selector(run) withObject:nil waitUntilDone:NO];
	
	BROADCAST_MESSAGE(kApplicationStartedMessage, nil);
}

- (void) toggleAds:(BOOL)onOff {
	if(! onOff) {
		[m_pAdsView removeFromSuperview];
	} else {
		[m_pGlView addSubview:m_pAdsView];
		[m_pAdsView getNextAd];
	}
}

- (JoyPad*) enableJoyPad {
	[m_pJoyPad reset];
	[[InputEngine sharedInstance] subscribe:m_pJoyPad];
	return m_pJoyPad;
}

- (void) disableJoyPad {
	[[InputEngine sharedInstance] unsubscribe:m_pJoyPad];
}

/* Run loop delegate work */
- (void) runLoopInitHook {
	TMLog(@"Init game run loop...");
	
	// Load up graphics system
	CGRect rect = [[UIScreen mainScreen] bounds];	
	
	// Setup window
	m_pWindow = [[[UIWindow alloc] initWithFrame:rect] autorelease];
	
	// Init global joypad
	m_pJoyPad = [[JoyPad alloc] init];

	// Init opengl
	m_pGlView = [[EAGLView alloc] initWithFrame:rect];	
	m_pGlView.multipleTouchEnabled = YES;	
	
	// Init sound system and set the master volume from settings
	[[TMSoundEngine sharedInstance] setMasterVolume:[[SettingsEngine sharedInstance] getFloatValue:@"sound"]];
	[[TMSoundEngine sharedInstance] start];
	
	// Load theme graphics, sounds, fonts, etc.
	[[ThemeManager sharedInstance] selectTheme:[[SettingsEngine sharedInstance] getStringValue:@"theme"]];
	[[ThemeManager sharedInstance] selectNoteskin:[[SettingsEngine sharedInstance] getStringValue:@"noteskin"]];
		
	// Start fetching news
	[NewsFetcher sharedInstance];
	
	// Set up OpenGL projection matrix
	glMatrixMode(GL_PROJECTION);
	glOrthof(0, rect.size.width, 0, rect.size.height, -1, 1);
	glMatrixMode(GL_MODELVIEW);
	
	// Initialize OpenGL states
	glDisable(GL_DEPTH_TEST);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glLoadIdentity();
	glClearColor(0,0,0,1.0f);
	
	// Clear
	glClear(GL_COLOR_BUFFER_BIT);
	
	// Add the gl view to our main window
	[m_pWindow addSubview:m_pGlView];		

	// Create the AdWhirl thing
	m_pAdsView = [ARRollerView requestRollerViewWithDelegate:self];
	[m_pAdsView setFrame:CGRectMake(0,430, 320, 50)];
	[m_pGlView addSubview:m_pAdsView];
	TMLog(@"Added the AdWhirl view.");
	
	// Show window
	[m_pWindow makeKeyAndVisible];
	
	TMLog(@"Done initializing opengl");
}

- (void) runLoopInitializedNotification {
	// Show FPS in debug mode only. FPS rendering slows things a lot.
#ifdef DEBUG 
	[[TapMania sharedInstance] registerObjectAtEnd:[[FPS alloc] init]];	// FPS drawing
#endif
	
	// Will start with main menu
	[[TapMania sharedInstance] switchToScreen:[[SongsCacheLoaderRenderer alloc] init] usingTransition:[FadeTransition class] timeIn:0.0f timeOut:0.5f];
		
	TMLog(@"Game run loop initialized...");
}

- (void) runLoopBeforeHook:(float)fDelta {
	// We must let the system handle all the events too
	while( CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.009, FALSE) == kCFRunLoopRunHandledSource);
}

- (void) runLoopAfterHook:(float)fDelta {
	// Must swap buffer after drawing
	[self.glView swapBuffers];
}

#pragma mark ARRollerDelegate required delegate method implementation
- (NSString*)adWhirlApplicationKey
{
    return @"c7b13290e38c102c96dc5b26aef5c1e9";
}

#pragma mark ARRollerDelegate optional delegate method implementations

- (void)rollerDidReceiveAd:(ARRollerView*)adWhirlView
{
	TMLog(@"Received ad from %@!", [m_pAdsView mostRecentNetworkName]);
	
}
- (void)rollerDidFailToReceiveAd:(ARRollerView*)adWhirlView usingBackup:(BOOL)YesOrNo
{
	TMLog(@"Failed to receive ad from %@.  Using Backup: %@", [m_pAdsView mostRecentNetworkName], YesOrNo ? @"YES" : @"NO");
}

- (void)rollerReceivedRequestForDeveloperToFulfill:(ARRollerView*)adWhirlView
{
	TMLog(@"Received Generic Notification.  Use this notification to do anything you want, such as making a ad request call to an ad network");
}

- (void)willDisplayWebViewCanvas
{
	TMLog(@"A webview canvas will be displayed now because the user tapped on a banner ad.");
}

- (void)didDismissWebViewCanvas
{
	TMLog(@"The webview canvas will now disappear.");
}


#pragma mark Singleton stuff
+ (TapMania *)sharedInstance {
    @synchronized(self) {
        if (sharedTapManiaDelegate == nil) {
            [[self alloc] init];
        }
    }
    return sharedTapManiaDelegate;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedTapManiaDelegate	== nil) {
            sharedTapManiaDelegate = [super allocWithZone:zone];
            return sharedTapManiaDelegate;
        }
    }
	
    return nil;
}


- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

- (void)release {
	// NOTHING
}

- (id)autorelease {
    return self;
}

@end