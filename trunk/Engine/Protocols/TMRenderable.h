//
//  TMRenderable.h
//  TapMania
//
//  Created by Alex Kremer on 26.11.08.
//  Copyright 2008 Godexsoft. All rights reserved.
//

@protocol TMRenderable

- (void) initForRendering:(NSObject*)data;
- (void) render:(NSNumber*) fDelta;

@end
