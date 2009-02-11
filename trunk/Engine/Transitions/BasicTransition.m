//
//  BasicTransition.m
//  TapMania
//
//  Created by Alex Kremer on 02.12.08.
//  Copyright 2008 Godexsoft. All rights reserved.
//

#import "BasicTransition.h"
#import "TMTransitionSupport.h"
#import "TapMania.h"
#import "TMRunLoop.h"	// For TMRunLoopPriority

#define kDefaultTransitionInTime	1.0f
#define kDefaultTransitionOutTime	1.0f

@interface BasicTransition (Protected)
- (BOOL) updateTransitionIn:(float)fDelta;
- (BOOL) updateTransitionOut:(float)fDelta;
@end


@implementation BasicTransition

- (id) initFromScreen:(AbstractRenderer*)fromScreen toScreen:(AbstractRenderer*)toScreen {
	self = [super init];
	if (!self)
		return nil;
	
	m_pFrom = fromScreen;
	m_pTo = toScreen;
	m_dTimePassed = 0.0f;
	m_nState = kTransitionStateInitializing;
	
	return self;
}

// May override in animating transitions
- (BOOL) updateTransitionIn:(float)fDelta {
	m_dTimePassed += fDelta;
	
	if(m_dTimePassed >= kDefaultTransitionInTime)
		return YES;
	return NO;
}

- (BOOL) updateTransitionOut:(float)fDelta {
	m_dTimePassed += fDelta;
	
	if(m_dTimePassed >= kDefaultTransitionOutTime)
		return YES;
	return NO;	
}

// TMTransition stuff. can be overriden to do some special stuff.
- (void) transitionInStarted {
}

- (void) transitionOutStarted {
	// Do custom initialization for transition if the object supports it
	if([m_pTo conformsToProtocol:@protocol(TMTransitionSupport)]){
		[m_pTo performSelector:@selector(setupForTransition)];
	}
	
	// Set new one and show it
	[[TapMania sharedInstance] setCurrentScreen:m_pTo];
	[[TapMania sharedInstance] registerObject:(NSObject*)m_pTo withPriority:kRunLoopPriority_Highest-1];	
}

- (void) transitionInFinished {
	// Do custom deinitialization for transition if the object supports it
	if([m_pFrom conformsToProtocol:@protocol(TMTransitionSupport)]){
		[m_pFrom performSelector:@selector(deinitOnTransition)];
	}	
	
	// Remove the current screen from rendering/logic runloop.
	[[TapMania sharedInstance] deregisterObject:(NSObject*)m_pFrom];	
	
	// Drop current screen
	[[TapMania sharedInstance] releaseCurrentScreen];
}

- (void) transitionOutFinished {
	// Remove our transition from runloop
	[[TapMania sharedInstance] deregisterObject:self];
}

// TMRenderable stuff
- (void)render:(NSNumber*)fDelta {	
	// OVERRIDE
}

// TMLogicUpdater stuff. should not override in subclasses.
- (void)update:(NSNumber*)fDelta {	
	switch(m_nState) {
		case kTransitionStateInitializing:
			// Start transition
			[self transitionInStarted];
		
			m_nState = kTransitionStateIn;
			m_dTimePassed = 0.0f;
			break;
			
		case kTransitionStateIn:
			// Do calculation
			if( [self updateTransitionIn:[fDelta doubleValue]] ) {
			
				// Switch to Out transition part
				[self transitionInFinished];
				m_nState = kTransitionStateOut;
				m_dTimePassed = 0.0f;
				[self transitionOutStarted];
			}			
			break;
			
		case kTransitionStateOut:
			// Do calculation
			if ( [self updateTransitionOut:[fDelta doubleValue]] ) {
				
				// Switch to finish
				[self transitionOutFinished];
				m_nState = kTransitionStateFinished;
			}
			break;
	}
}

@end
