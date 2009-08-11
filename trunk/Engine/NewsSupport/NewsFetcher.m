//
//  NewsFetcher.m
//  TapMania
//
//  Created by Alex Kremer on 8/11/09.
//  Copyright 2009 Godexsoft. All rights reserved.
//

#import "NewsFetcher.h"
#import "SettingsEngine.h"
#import "VersionInfo.h"

// This is a singleton class, see below
static NewsFetcher *sharedNewsFetcherDelegate = nil;

@interface NewsFetcher (Private)
- (void) checkForNews;
- (void) stopChecking;
- (void) startChecking;
@end


@implementation NewsFetcher

// This is a periodic task
// Called once in 5 minutes
- (void) checkForNews {
	m_bRunning = YES;

	while (m_bRunning) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		@synchronized (self) {
			NSString* currentNewsVersion = [NSString stringWithContentsOfURL:[NSURL URLWithString:[TAPMANIA_URL stringByAppendingString:TAPMANIA_NEWS_VERSION_PAGE]]];
			if(currentNewsVersion != nil) {
				TMLog(@"Found news version: %@", currentNewsVersion);
				
				if(! [currentNewsVersion isEqualToString:[[SettingsEngine sharedInstance] getStringValue:@"newsversion"]]) {
					TMLog(@"Should fetch news!");
					m_sNews = [[NSString stringWithContentsOfURL:[NSURL URLWithString:[TAPMANIA_URL stringByAppendingString:TAPMANIA_NEWS_PAGE]]] retain];
					
					if(m_sNews != nil) {				
						m_bGotNews = YES;
						m_sNewsVersion = [currentNewsVersion retain];
					}
				}
			} else {
				m_bGotNews = NO;
				m_sNews = @"";
			}	
			
		}
		
		[pool release];
		
		// 5 minutes waiting
		[NSThread sleepForTimeInterval:300];
	}
}

- (id) init {
	self = [super init];
	if(!self)
		return nil;
	
	m_bGotNews = NO;
	m_sNews = @"";
	m_sNewsVersion = @"";
	
	// Start polling for news with 5 minutes periodics
	m_pThread = [[NSThread alloc] initWithTarget:self selector:@selector(checkForNews) object:nil];
	[self startChecking];
	
	return self;
}

- (void) stopChecking {
	m_bRunning = NO;
}

- (void) startChecking {
	[m_pThread start];
}

- (BOOL) hasUnreadNews {
	@synchronized (self) {
		return m_bGotNews;
	}
}

- (NSString*) getUnreadNews {
	@synchronized (self) {
		if(m_bGotNews) {
			m_bGotNews = NO;
	
			// Save latest news version
			[[SettingsEngine sharedInstance] setStringValue:m_sNewsVersion forKey:@"newsversion"];
	
			return m_sNews;
		}
	}
	
	return @"";
}

#pragma mark Singleton stuff

+ (NewsFetcher *)sharedInstance {
    @synchronized(self) {
        if (sharedNewsFetcherDelegate == nil) {
            [[self alloc] init];
        }
    }
    return sharedNewsFetcherDelegate;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedNewsFetcherDelegate	== nil) {
            sharedNewsFetcherDelegate = [super allocWithZone:zone];
            return sharedNewsFetcherDelegate;
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
