//
//  AbstractRenderer.m
//  TapMania
//
//  Created by Alex Kremer on 05.11.08.
//  Copyright 2008 Godexsoft. All rights reserved.
//

#import "AbstractRenderer.h"


@implementation AbstractRenderer

- (void) initForRendering:(NSObject*)data {
	// Override if you need something specific with glView
}

- (void) render:(NSNumber*)fDelta {
	NSException *ex = [NSException exceptionWithName:@"AbstractClass" 
											  reason:@"You may not call render on the abstract renderer class." userInfo:nil];
	@throw ex;
}

@end