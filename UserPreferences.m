//
//  UserPreferences.m
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "UserPreferences.h"
#import "Extensions.h"
@import ScreenSaver;

static const NSUInteger DEFAULT_FONT_SIZE = 0;

@interface UserPreferences () {
    NSFont *_textFont, *_attributionFont;
    ScreenSaverDefaults *_screenSaverDefaults;
    NSMutableArray *_observers;
}

@end

@implementation UserPreferences
@synthesize documentFileURL = _documentFileURL;

- (NSString *)backgroundName {
    return [_screenSaverDefaults stringForKey:kBackgroundName];
}

- (void)setBackgroundName:(NSString *)backgroundName {
    [_screenSaverDefaults setObject:backgroundName forKey:kBackgroundName];
    [self notifyObservers];
}

- (NSString *)filterName {
    return [_screenSaverDefaults stringForKey:kFilterName];
}

- (void)setFilterName:(NSString *)filterName {
    [_screenSaverDefaults setObject:filterName forKey:kFilterName];
    [self notifyObservers];
}

- (NSString *)styleName {
    return [_screenSaverDefaults stringForKey:kStyleName];
}

- (void)setStyleName:(NSString *)styleName {
    [_screenSaverDefaults setObject:styleName forKey:kStyleName];
    [self notifyObservers];
}

#pragma mark Colours

- (NSColor *)textColour {
    return [_screenSaverDefaults colourForKey:kTextColour];
}

- (void)setTextColour:(NSColor *)textColour {
    [_screenSaverDefaults setColour:textColour forKey:kTextColour];
    [self notifyObservers];
}

- (NSColor *)attributionColour {
    return [_screenSaverDefaults colourForKey:kAttributionColour];
}

- (void)setAttributionColour:(NSColor *)attributionColour {
    [_screenSaverDefaults setColour:attributionColour forKey:kAttributionColour];
    [self notifyObservers];
}

#pragma mark Fonts

- (NSFont *)textFont {
    if (!_textFont) {
        _textFont = [_screenSaverDefaults fontForKey:kTextFont];
    }
    if (!_textFont) {
        _textFont = [NSFont systemFontOfSize:DEFAULT_FONT_SIZE];  // If the specified font isn't found, use one guaranteed to be there.
    }
    return _textFont;
}

- (void)setTextFont:(NSFont *)textFont {
    if(textFont == nil) { NSLog(@"Invalid text font set in preferences."); }
    if (textFont) {
        _textFont = textFont;
        [_screenSaverDefaults setFont:_textFont forKey:kTextFont];
        [self notifyObservers];
    }
}

- (NSString *)textFontName {
    return [_screenSaverDefaults stringForKey:kTextFont];
}

- (void)setTextFontName:(NSString *)textFontName {
    [_screenSaverDefaults setObject:textFontName forKey:kTextFont];
    _textFont = [_screenSaverDefaults fontForKey:kTextFont];
    [self notifyObservers];
}

- (NSFont *)attributionFont {
    if (!_attributionFont) {
        _attributionFont = [_screenSaverDefaults fontForKey:kAttributionFont];
    }
    if (!_attributionFont) {
        _attributionFont = [NSFont systemFontOfSize:DEFAULT_FONT_SIZE];  // If the specified font isn't found, use one guaranteed to be there.
    }
    return _attributionFont;
}

- (void)setAttributionFont:(NSFont *)attributionFont {
    if(attributionFont == nil) { NSLog(@"Invalid attribution font set in preferences."); }
    if (attributionFont) {
        _attributionFont = attributionFont;
        [_screenSaverDefaults setFont:_attributionFont forKey:kAttributionFont];
        [self notifyObservers];
    }
}

- (NSString *)attributionFontName {
    return [_screenSaverDefaults stringForKey:kAttributionFont];
}

- (void)setAttributionFontName:(NSString *)attributionFontName {
    [_screenSaverDefaults setObject:attributionFontName forKey:kAttributionFont];
    _attributionFont = [_screenSaverDefaults fontForKey:kAttributionFont];
    [self notifyObservers];
}

- (NSString *)textFontDetails {
    return self.textFont.description;
}

-(NSString *)attributionFontDetails {
    return self.attributionFont.description;
}



#pragma mark Methods

+ (instancetype)sharedPreferences {
    static UserPreferences *singleton = nil;
    if (!singleton) {
        singleton = [[UserPreferences alloc] init];
    }
    return singleton;
}

-(instancetype)init {
    self = [super init];
    if (!self) { return nil; }
    
    _observers = [NSMutableArray array];
    _screenSaverDefaults = [ScreenSaverDefaults defaultsForModuleWithName:self.bundleIdentifier];
    if (!_screenSaverDefaults) {  NSLog(@"Couldn't initialise screensaverDefaults"); }
    [_screenSaverDefaults registerMyDefaults];
    
        // Find the document URL by default under the user's Documents directory.
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectoryURL = urls[0];
    _documentFileURL = [NSURL URLWithString:@"net-sigs.xml" relativeToURL:documentsDirectoryURL];
    return self;
}


-(void)synchronise {
    [_screenSaverDefaults synchronize];
}


- (NSString *)bundleIdentifier {
    return @"Patrick-Wallace.PWFortune";
}


-(void)addObserver:(id<UserPreferencesObserver>)observer {
    if (![_observers containsObject:observer]) {
        [_observers addObject:observer];
    }
}

- (void)removeObserver:(id<UserPreferencesObserver>)observer {
    [_observers removeObject:observer];
}

- (void)notifyObservers {
    for (id<UserPreferencesObserver> observer in _observers) {
        [observer userPreferencesChanged:self];
    }
}

@end


    // Keys for the application preferences.
NSString * const kTextFont = @"TextFont", *const kAttributionFont = @"AttributionFont", *const kTextColour = @"TextColour", *const kAttributionColour = @"AttributionColour", *const kBackgroundName = @"BackgroundName", *const kFilterName = @"FilterName", *const kStyleName = @"StyleName";


