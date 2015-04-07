//
//  UserPreferences.m
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "UserPreferences.h"
@import ScreenSaver;

static const NSUInteger DEFAULT_FONT_SIZE = 0;

@interface UserPreferences () {
    NSFont *_textFont, *_attributionFont;
    ScreenSaverDefaults *_screenSaverDefaults;
    NSMutableArray *_observers;
}
    /// Hard-coded bundle identifier. This is used so we get access to the preferences no matter which app launches us.
@property (nonatomic, readonly) NSString *bundleIdentifier;

@end

@implementation UserPreferences

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

- (NSURL *)quotesFileURL {
        // If we have a URL in the preferences, return that URL.  Otherwise return a URL to the default script in the bundle.
    NSURL *urlFromPrefs = [_screenSaverDefaults URLForKey:kQuotesURL];
    return urlFromPrefs;
}

- (void)setQuotesFileURL:(NSURL *)documentFileURL {
    [_screenSaverDefaults setURL:documentFileURL forKey:kQuotesURL];
    [self notifyObservers];
}

- (NSURL *)fallbackQuotesFileURL {
    NSBundle *ourBundle = [NSBundle bundleForClass:self.class];
    NSURL *url = [ourBundle URLForResource:@"Default Quotes" withExtension:@"xml"];
    if (!url) {
        NSLog(@"Default quotes URL not found in Screensaver bundle %@", ourBundle);
    }
    return url;
}

#pragma mark Colours

- (NSColor *)textColour {
    return [self colourForKey:kTextColour];
}

- (void)setTextColour:(NSColor *)textColour {
    [self setColour:textColour forKey:kTextColour];
    [self notifyObservers];
}

- (NSColor *)attributionColour {
    return [self colourForKey:kAttributionColour];
}

- (void)setAttributionColour:(NSColor *)attributionColour {
    [self setColour:attributionColour forKey:kAttributionColour];
    [self notifyObservers];
}

#pragma mark Fonts

- (NSFont *)textFont {
    if (!_textFont) {
        _textFont = [self fontForKey:kTextFont];
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
        [self setFont:_textFont forKey:kTextFont];
        [self notifyObservers];
    }
}

- (NSString *)textFontName {
    return [_screenSaverDefaults stringForKey:kTextFont];
}

- (void)setTextFontName:(NSString *)textFontName {
    [_screenSaverDefaults setObject:textFontName forKey:kTextFont];
    _textFont = [self fontForKey:kTextFont];
    [self notifyObservers];
}

- (NSFont *)attributionFont {
    if (!_attributionFont) {
        _attributionFont = [self fontForKey:kAttributionFont];
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
        [self setFont:_attributionFont forKey:kAttributionFont];
        [self notifyObservers];
    }
}

- (NSString *)attributionFontName {
    return [_screenSaverDefaults stringForKey:kAttributionFont];
}

- (void)setAttributionFontName:(NSString *)attributionFontName {
    [_screenSaverDefaults setObject:attributionFontName forKey:kAttributionFont];
    _attributionFont = [self fontForKey:kAttributionFont];
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
    [self registerMyDefaults];
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ <%@>", super.description, _screenSaverDefaults];
}

-(void)synchronise {
    [_screenSaverDefaults synchronize];
}

- (void)removeAll {
    for (NSString *key in _screenSaverDefaults.dictionaryRepresentation.allKeys) {
        [_screenSaverDefaults removeObjectForKey:key];
    }
    [self notifyObservers];
}

#pragma mark Observers

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


#pragma mark Private methods

- (NSString *)bundleIdentifier {
    return @"Patrick-Wallace.PWFortune";
}


- (void)registerMyDefaults {
        // HACK: These are hard-coded to the view that I think looks 'best'. There is probably a better way of doing this.
        // If they aren't around anymore, the various managers will substitute an ugly-but-visible alternative anyway.
    [_screenSaverDefaults registerDefaults:@{kTextFont          : @"HelveticaNeue-Bold::48",
                                             kAttributionFont   : @"Optima-Bold::36",
                                             kTextColour        : [NSKeyedArchiver archivedDataWithRootObject:[NSColor magentaColor]],
                                             kAttributionColour : [NSKeyedArchiver archivedDataWithRootObject:[NSColor blueColor   ]],
                                             kFilterName        : @"Divide Blend",
                                             kStyleName         : @"Green Gold",
                                             kBackgroundName    : @"Green Glitter"}];
    [_screenSaverDefaults synchronize];
    
        // Check it worked.
    if( [self colourForKey:kAttributionColour] == nil) { NSLog(@"User defaults - Stored attribution colour came back as nil."); }
}

- (NSColor*) colourForKey:(NSString *)key {
    NSData *data = [_screenSaverDefaults objectForKey:key];
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return color;
}

- (void) setColour:(NSColor *)colour forKey:(NSString *)key {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:colour];
    [_screenSaverDefaults setObject:data forKey:key];
}

-(NSFont *) fontForKey:(NSString *)key {
    NSString *fontDescription = [_screenSaverDefaults stringForKey:key];
    NSArray *array = [fontDescription componentsSeparatedByString:@"::"];
    NSString *name = nil;
    NSUInteger size = [NSFont systemFontSize];
    name = array[0];
    if (array.count >= 2) {
        NSString *sizeStr = array[1];
        size = sizeStr.integerValue;
    }
    
    NSFont *font = [NSFont fontWithName:name size:size];
    return font;
}

-(void) setFont:(NSFont *)font forKey:(NSString *)key {
    NSString *name = font.fontName;
    NSUInteger size = font.pointSize;
    NSString *fontDescription = [NSString stringWithFormat:@"%@::%lu", name, size];
    [_screenSaverDefaults setObject:fontDescription forKey:key];
}

@end


    // Keys for the application preferences.
NSString * const kTextFont = @"TextFont", *const kAttributionFont = @"AttributionFont", *const kTextColour = @"TextColour", *const kAttributionColour = @"AttributionColour", *const kBackgroundName = @"BackgroundName", *const kFilterName = @"FilterName", *const kStyleName = @"StyleName", *const kQuotesURL = @"QuotesURL";


