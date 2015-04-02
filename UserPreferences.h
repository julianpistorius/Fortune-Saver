//
//  UserPreferences.h
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Cocoa;

@interface UserPreferences : NSObject

    /// Hard-coded bundle identifier. This is used so we get access to the preferences no matter which app launches us.
@property (nonatomic, readonly) NSString *bundleIdentifier;

#pragma mark Properties which will eventually be pulled from the preferences.
@property (nonatomic, strong) NSColor *textColour, *attributionColour;
@property (nonatomic, readonly) NSURL *documentFileURL;

    /// Fonts specified
@property (nonatomic, strong) NSFont *textFont, *attributionFont;

    /// Text description of the font specified. For error messages and logs.
@property (nonatomic, readonly) NSString *textFontDetails, *attributionFontDetails;

- (void)synchronise;

@end

    // Keys for the application preferences.
extern NSString * const kTextFont, *const kAttributionFont, *const kTextColour, *const kAttributionColour;
