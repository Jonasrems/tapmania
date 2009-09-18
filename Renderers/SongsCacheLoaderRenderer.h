//
//  SongsCacheLoaderRenderer.h
//  TapMania
//
//  Created by Alex Kremer on 22.01.09.
//  Copyright 2008-2009 Godexsoft. All rights reserved.
//

#import "TMScreen.h"
#import "TMSongsLoaderSupport.h"

@class Texture2D;

@interface SongsCacheLoaderRenderer : TMScreen <TMSongsLoaderSupport> {
	BOOL	m_bAllSongsLoaded;
	BOOL	m_bTransitionIsDone;
	BOOL	m_bGlobalError;
	BOOL	m_bTextureShouldChange;
	
	NSString*	m_sCurrentMessage;
	Texture2D*	m_pCurrentTexture;
	
	NSThread* m_pThread;
	NSLock*   m_pLock;
}

@end