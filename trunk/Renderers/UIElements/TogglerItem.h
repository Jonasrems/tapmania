//
//  TogglerItem.h
//  TapMania
//
//  Created by Alex Kremer on 12.11.08.
//  Copyright 2008 Godexsoft. All rights reserved.
//

#import "MenuItem.h"

@class MenuItem, Texture2D, TMCommand;

/* This object is a pair with title=>value */
@interface TogglerItemObject : NSObject {
	NSString*			m_sTitle;
	NSObject*			m_pValue;
	CGSize				m_oSize;

	float				m_fFontSize;
	NSString*			m_sFontName;
	UITextAlignment		m_Align;
	
	TMCommand*			m_pCmdList;	
	Texture2D*			m_pText;	// The title as texture
}

@property (retain, nonatomic, readonly) NSString* m_sTitle;
@property (retain, nonatomic, readonly) Texture2D* m_pText;
@property (retain, nonatomic) NSObject* m_pValue;

- (id) initWithSize:(CGSize)size andFontSize:(float)fontSize;
- (id) initWithTitle:(NSString*)lTitle value:(NSObject*)lValue size:(CGSize)size andFontSize:(float)fontSize;
- (void) setName:(NSString*)inName;	// For name command (sets value automatically if none set)
- (void) setValue:(NSObject*)inVal;	// For value command
- (void) setFont:(NSString*)inName;	// For font command
- (void) setFontSize:(NSNumber*)inSize;	// For fontsize command
- (void) setAlignment:(NSString*)inAlign;	// For alignment command
- (void) setCmdList:(TMCommand*)inCmdList;
- (void) onSelect;

// Used by the value,VAL command to set current value
- (void) setValue:(NSObject*)value;

@end

/* The toggler self */
@interface TogglerItem : MenuItem {
	NSMutableArray*		m_aElements;			// All the elements which are available in this toggler item (TogglerItemObjects)
	int					m_nCurrentSelection;	// Index of currently selected element
}

- (void) addItem:(NSObject*)value withTitle:(NSString*)title;
- (void) removeItemAtIndex:(int) index;
- (void) removeAll;

- (int) findIndexByValue:(NSObject*)value;
- (void) selectItemAtIndex:(int) index;
- (void) toggle;
- (TogglerItemObject*) getCurrent;

// Used by the value,VAL command to set current value
- (void) setValue:(NSObject*)value;

@end
