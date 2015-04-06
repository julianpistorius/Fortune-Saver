//
//  UserPreferences.h
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Cocoa;
@class UserPreferences;

@protocol UserPreferencesObserver <NSObject>

- (void)userPreferencesChanged: (UserPreferences *)userPreferences;

@end

@interface UserPreferences : NSObject

+ (instancetype) sharedPreferences;

#pragma mark -

    /// Hard-coded bundle identifier. This is used so we get access to the preferences no matter which app launches us.
@property (nonatomic, readonly) NSString *bundleIdentifier;

#pragma mark Properties pulled from the preferences.
@property (nonatomic, strong) NSColor *textColour, *attributionColour;
@property (nonatomic, readonly) NSURL *documentFileURL;

    /// The name of the selected background animation.
@property (nonatomic, strong) NSString *backgroundName;

    /// The name of the selected Core Image filter.
@property (nonatomic, strong) NSString *filterName;

    /// The name of the selected style.
@property (nonatomic, strong) NSString *styleName;

    /// Fonts specified
@property (nonatomic, strong) NSFont *textFont, *attributionFont;
    /// Fonts specified by their unique short names, e.g. "HelveticaNeue-Bold::16"
@property (nonatomic, strong) NSString *textFontName, *attributionFontName;

    /// Text description of the font specified. For error messages and logs.
@property (nonatomic, readonly) NSString *textFontDetails, *attributionFontDetails;

#pragma mark Methods

- (void)synchronise;

- (void)addObserver: (id<UserPreferencesObserver>) observer;
- (void)removeObserver: (id<UserPreferencesObserver>) observer;

@end

    // Keys for the application preferences.
extern NSString * const kTextFont, *const kAttributionFont, *const kTextColour, *const kAttributionColour, *const kBackgroundName, *const kFilterName, *const kStyleName;
