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

#pragma mark - Properties pulled from the preferences.

@property (nonatomic, strong) NSColor *textColour, *attributionColour;

    /// The user-specified URL for the quotes XML file, or nil if none have been specified.
@property (nonatomic, copy) NSURL *quotesFileURL;

    /// The hard-coded URL for the quotes XML file included in the bundle in case the user hasn't set quotesFileURL manually.
@property (nonatomic, readonly) NSURL *fallbackQuotesFileURL;

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

    /// Remove all the preferences set, returning the system to the default state.
- (void)removeAll;

    /// Writes out our changes to the disk.
- (void)synchronise;

#pragma mark Observers

- (void)addObserver: (id<UserPreferencesObserver>) observer;
- (void)removeObserver: (id<UserPreferencesObserver>) observer;

@end

    // Keys for the application preferences.
extern NSString * const kTextFont, *const kAttributionFont, *const kTextColour, *const kAttributionColour, *const kBackgroundName, *const kFilterName, *const kStyleName, *const kQuotesURL;
