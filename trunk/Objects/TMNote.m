//
//  TMNote.m
//  TapMania
//
//  Created by Alex Kremer on 10.11.08.
//  Copyright 2008 Godexsoft. All rights reserved.
//

#import "TMNote.h"


@implementation TMNote

@synthesize time, tillTime, beatType, isHit, hitTime;

- (id) initWithTime:(double) lTime tillTime:(double) lTillTime {
	self = [super init];
	if(!self)
		return nil;
	
	time = lTime;
	tillTime = lTillTime;
	beatType = 0; // FIXME
	
	isHit = NO;
	hitTime = 0.0f;
	
	return self;
}

- (void) hit:(double)lHitTime {
	if(!isHit){
		isHit = YES;
		hitTime = lHitTime;
	}
}

@end