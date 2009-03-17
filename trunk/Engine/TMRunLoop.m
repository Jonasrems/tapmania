//
//  TMRunLoop.m
//  TapMania
//
//  Created by Alex Kremer on 26.11.08.
//  Copyright 2008 Godexsoft. All rights reserved.
//

#import "TMRunLoop.h"

#import "TMObjectWithPriority.h"
#import "TMRenderable.h"
#import "TMLogicUpdater.h"
#import "TimingUtil.h"
#import "TapMania.h"
#import <syslog.h>

@interface TMRunLoop (Private)
- (void) worker; 
@end

@implementation TMRunLoop

@synthesize m_idDelegate;

- (id) init {
	self = [super init];
	if(!self)
		return nil;

	m_aObjects = [[NSMutableArray arrayWithCapacity:10] retain];
	
	m_bStopRequested = NO;
	m_bActualStopState = YES; // Initially stopped
		
	return self;
}

- (void) dealloc {
	[m_aObjects release];
	
	[super dealloc];
}

- (void) run {
	m_bActualStopState = NO; // Running
	[self worker];
}

- (void) stop {
	m_bStopRequested = YES;
}

- (BOOL) isStopped {
	return m_bActualStopState;
}

/* Add stuff to the arrays and sort them on the fly */
- (void) registerObject:(NSObject*) obj withPriority:(TMRunLoopPriority) priority {
	// Wrapping of priority
	if (priority < kRunLoopPriority_Lowest) {
		priority = kRunLoopPriority_Lowest;
	} else if (priority > kRunLoopPriority_Highest) {
		priority = kRunLoopPriority_Highest;
	}
	
	int i = 0;
	if([m_aObjects count] > 0) {
		for(i=0; i<[m_aObjects count]; i++){
			if([(TMObjectWithPriority*)[m_aObjects objectAtIndex:i] m_uPriority] <= priority) {
				break;
			}
		}
	}
	
	// Add new object at 'i' and shift others if required
	TMObjectWithPriority* wrapper = [[TMObjectWithPriority alloc] initWithObj:obj andPriority:priority];
	if(i < [m_aObjects count]) { 
		[m_aObjects insertObject:wrapper atIndex:i]; 
	} else {
		[m_aObjects addObject:wrapper];	// To the end
	}
}

- (void) deregisterObject:(NSObject*) obj {
	int i = 0;
	if([m_aObjects count] > 0) {
		for(i=0; i<[m_aObjects count]; i++){
			if([(TMObjectWithPriority*)[m_aObjects objectAtIndex:i] m_pObj] == obj) {
				[m_aObjects removeObjectAtIndex:i];
				return;
			}
		}
	}
}

- (void) deregisterAllObjects {
	int i;
	for(i=0; i<[m_aObjects count]; i++){
		TMObjectWithPriority* obj = [m_aObjects objectAtIndex:i];
		[obj release];
	}	
	
	[m_aObjects removeAllObjects];
}

/* Private worker */
- (void) worker {
	// int framesCounter = 0;
	float prevTime = [TimingUtil getCurrentTime] - 1.0f;
	// float totalTime = 0.0f;

	/* Call initialization routine on delegate */
	if(m_idDelegate && [m_idDelegate respondsToSelector:@selector(runLoopInitHook)]) {
		[m_idDelegate performSelector:@selector(runLoopInitHook) withObject:nil];
		
		if([m_idDelegate respondsToSelector:@selector(runLoopInitializedNotification)]){
			[m_idDelegate performSelector:@selector(runLoopInitializedNotification) withObject:nil];
		}
	}
	
	while (!m_bStopRequested) {
		float currentTime = [TimingUtil getCurrentTime];
		
		float delta = currentTime-prevTime;
		// NSNumber* nDelta = [NSNumber numberWithFloat:delta];
		
		prevTime = currentTime;
		
		/* Now call the runLoopBeforeHook method on the delegate */
		if(m_idDelegate && [m_idDelegate respondsToSelector:@selector(runLoopBeforeHook:)]) { 
			[m_idDelegate runLoopBeforeHook:delta];
		}
		
		/* Do the actual work */
		/* First update all objects */
		int i;
		for(i=0; i<[m_aObjects count]; i++){
			TMObjectWithPriority* wrapper = [m_aObjects objectAtIndex:i];
			NSObject* obj = [wrapper m_pObj];
			
			if([obj conformsToProtocol:@protocol(TMLogicUpdater)]) {
				// Ignore this warning.
				[(id<TMLogicUpdater>)obj update:delta];
			}
		}

		/* Now draw all objects */
		for(i=0; i<[m_aObjects count]; i++){
			TMObjectWithPriority* wrapper = [m_aObjects objectAtIndex:i];
			NSObject* obj = [wrapper m_pObj];
			
			if([obj conformsToProtocol:@protocol(TMRenderable)]) {
				// Ignore this warning.				
				[(id<TMRenderable>)obj render:delta];
			}
		}
		
		/* Now call the runLoopAfterHook method on the delegate */
		if(m_idDelegate && [m_idDelegate respondsToSelector:@selector(runLoopAfterHook:)]) { 
			[m_idDelegate runLoopAfterHook:delta];
		}		
	}
	
	// Mark as stopped
	m_bActualStopState = YES;
}

@end
