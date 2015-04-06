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
}

@end

@implementation UserPreferences
@synthesize documentFileURL = _documentFileURL;

- (NSString *)backgroundName {
    return [_screenSaverDefaults stringForKey:kBackgroundName];
}

- (void)setBackgroundName:(NSString *)backgroundName {
    [_screenSaverDefaults setObject:backgroundName forKey:kBackgroundName];
}

#pragma mark Colours

- (NSColor *)textColour {
    NSColor *colour = [_screenSaverDefaults colourForKey:kTextColour];
//    return /*[NSColor colorWithWhite:1.0 alpha:0.5];*/ [[NSColor blackColor] colorWithAlphaComponent:0.5];
    return colour;
}

- (void)setTextColour:(NSColor *)textColour {
    [_screenSaverDefaults setColour:textColour forKey:kTextColour];
}

- (NSColor *)attributionColour {
    NSColor *colour = [_screenSaverDefaults colourForKey:kAttributionColour];
//    return /*[[NSColor redColor] colorWithAlphaComponent:0.75]*/ [NSColor magentaColor];
    return colour;
}

- (void)setAttributionColour:(NSColor *)attributionColour {
    [_screenSaverDefaults setColour:attributionColour forKey:kAttributionColour];
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
    NSAssert(textFont != nil, @"Invalid text font set in preferences.");
    if (textFont) {
        _textFont = textFont;
        [_screenSaverDefaults setFont:_textFont forKey:kTextFont];
    }
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
    NSAssert(attributionFont != nil, @"Invalid attribution font set in preferences.");
    if (attributionFont) {
        _attributionFont = attributionFont;
        [_screenSaverDefaults setFont:_attributionFont forKey:kAttributionFont];
    }
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
    
    _screenSaverDefaults = [ScreenSaverDefaults defaultsForModuleWithName:self.bundleIdentifier];
    NSAssert(_screenSaverDefaults, @"Couldn't initialise screensaverDefaults");
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


@end


    // Keys for the application preferences.
NSString * const kTextFont = @"TextFont", *const kAttributionFont = @"AttributionFont", *const kTextColour = @"TextColour", *const kAttributionColour = @"AttributionColour", *const kBackgroundName = @"BackgroundName";


