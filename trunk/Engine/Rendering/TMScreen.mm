//
//  TMScreen.m
//  TapMania
//
//  Created by Alex Kremer on 10.09.09.
//  Copyright 2009 Godexsoft. All rights reserved.
//

#import "TMScreen.h"
#import "InputEngine.h"

@implementation TMScreen

- (id) init {
	// A screen is always fullscreen :P
	self = [super initWithShape:CGRectMake(0, 0, 320, 480)];
	if(!self)
		return nil;
		
	return self;
}

/* TMTransitionSupport methods */
- (void) setupForTransition {
	[[InputEngine sharedInstance] subscribe:self];
}

- (void) deinitOnTransition {
	[[InputEngine sharedInstance] unsubscribe:self];
}

@end
