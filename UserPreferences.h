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
@property (nonatomic, readonly) NSColor *textColour, *attributionColour;
@property (nonatomic, readonly) NSURL *documentFileURL;
@property (nonatomic, readonly) NSString *fontName;
@property (nonatomic, readonly) CGFloat fontSize;

@end
