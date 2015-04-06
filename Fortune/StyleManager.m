//
//  StyleManager.m
//  Fortune
//
//  Created by Patrick Wallace on 06/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "StyleManager.h"
@class StyleManager;

static StyleManager *singleton = nil;
static NSString *const CUSTOM = @"Custom";

@interface StyleManager () {
        // Key: Name, Value = Style path
    NSMutableDictionary *_styleObjects; // NSString -> NSString
    UserPreferences *_userPreferences;
}

@end

@implementation StyleManager

+ (instancetype)sharedManager {
    if (!singleton) {
        singleton = [[StyleManager alloc] init];
    }
    return singleton;
}


- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }
    
    _userPreferences = [UserPreferences sharedPreferences];
    [_userPreferences addObserver:self];
    
    [self reload];
 
    return self;
}

- (void)dealloc {
    [_userPreferences removeObserver:self];
}

- (void)reload {
       // Load all the backgrounds into the dictionary.
    _styleObjects = [self getStyleFiles];
    
            // If we find the style in the preferences, then set it as selected here.  If it has been removed then leave the selected flag as nil.
    NSString *defaultStyle = _userPreferences.styleName;
    if (_styleObjects[defaultStyle] || [defaultStyle isEqualToString:CUSTOM]) {
        self.selectedStyleName = defaultStyle;
    }
}

- (NSArray *)styleNames {
    NSMutableArray *names = _styleObjects.allKeys.mutableCopy;
    [names addObject:CUSTOM];
    return names;
}

- (void)setSelectedStyleName:(NSString *)selectedStyleName {
    if (![_selectedStyleName isEqualToString:selectedStyleName]) {
        _selectedStyleName = selectedStyleName;
        _userPreferences.styleName = selectedStyleName;
    }
}

- (NSString *)customStyleName {
    return CUSTOM;
}

- (NSMutableDictionary *)getStyleFiles {
    NSMutableDictionary *styleObjects = [NSMutableDictionary dictionary];
    NSBundle *ourBundle = [NSBundle bundleForClass:self.class];
    for (NSString *style in [ourBundle pathsForResourcesOfType:@"plist" inDirectory:@"Styles"]) {
        NSString *title = style.stringByDeletingPathExtension.lastPathComponent;
        styleObjects[title] = style;
    }
    if (styleObjects.count == 0) {
        NSLog(@"Couldn't find any styles in bundle %@", ourBundle);
    }
    return styleObjects;
}

- (NSColor *) colourFromDictionary: (NSDictionary*)dictionary forKey:(NSString *)key {
    NSData *colourData = dictionary[key];
    if (colourData) {
        NSColor *colour = [NSKeyedUnarchiver unarchiveObjectWithData:colourData];
        if (colour) {
            return colour;
        }
        else { NSLog(@"%@: NSData %@ couldn't be converted into an NSColor object", key, colourData); }
    }
    return nil;
}

- (void)applyStyleNamed:(NSString *)styleName {
        // Nothing to do for the custom style.
    if ([styleName isEqualToString:CUSTOM]) {
        return;
    }
        // Load the file as a plist, get the data from it and set the preferences. This should trigger a cascade of preference notifications which should change the other controls.
    NSString *styleFilename = _styleObjects[styleName];
    if (!styleFilename) {
        NSLog(@"Unable to find filename for style name [%@]", styleName);
        return;
    }
    
    NSError *error = nil;
    NSData *inputData = [NSData dataWithContentsOfFile:styleFilename options:0 error:&error];
    if (!inputData) {
        NSLog(@"Error loading style file %@: %@", styleFilename, error);
        return;
    }
    
    error = nil;
    NSDictionary *propertyList = [NSPropertyListSerialization propertyListWithData:inputData options:0 format:NULL error:&error];
    if (!propertyList) {
        NSLog(@"Error serializing property list %@: %@", inputData, error);
        return;
    }

    _selectedStyleName = styleName;
    _userPreferences.styleName = styleName;
    
    NSColor *textColour = [self colourFromDictionary:propertyList forKey:kTextColour];
    if (textColour) {
        _userPreferences.textColour = textColour;
    }
    
    NSColor *attributionColour = [self colourFromDictionary:propertyList forKey:kAttributionColour];
    if (attributionColour) {
        _userPreferences.attributionColour = attributionColour;
    }
    
    NSString *textFont = propertyList[kTextFont];
    NSLog(@"");
    if (textFont) {
        _userPreferences.textFontName = textFont;
    }
    
    NSString *attributionFontName = propertyList[kAttributionFont];
    if (attributionFontName) {
        _userPreferences.attributionFontName = attributionFontName;
    }
    
    NSString *filterName = propertyList[kFilterName];
    if (filterName) {
        _userPreferences.filterName = filterName;
    }
    
    NSString *backgroundName = propertyList[kBackgroundName];
    if (backgroundName) {
        _userPreferences.backgroundName = backgroundName;
    }
}

- (BOOL)styleExists:(NSString *)styleName {
    return _styleObjects[styleName] != nil;
}

- (void)addStyle:(NSString *)newStyleName {
    NSBundle *thisBundle = [NSBundle bundleForClass:self.class];
    NSString *styleFolder = [thisBundle pathForResource:@"Styles" ofType:@""];
    if (!styleFolder) {
        NSLog(@"Couldn't get style folder in bundle %@", thisBundle);
        return;
    }
    
    NSMutableDictionary *styleDict = [NSMutableDictionary dictionary];
    NSColor *textColour = _userPreferences.textColour;
    NSData *textColourData = [NSKeyedArchiver archivedDataWithRootObject:textColour];
    NSColor *attributionColour = _userPreferences.attributionColour;
    NSData *attributionColourData = [NSKeyedArchiver archivedDataWithRootObject:attributionColour];
    
    styleDict[kTextColour] = textColourData;
    styleDict[kAttributionColour] = attributionColourData;
    styleDict[kTextFont] = _userPreferences.textFontName;
    styleDict[kAttributionFont] = _userPreferences.attributionFontName;
    styleDict[kBackgroundName] = _userPreferences.backgroundName;
    styleDict[kFilterName] = _userPreferences.filterName;
    
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:styleDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (!plistData) {
        NSLog(@"Error saving property list %@, error = %@", styleDict, error);
        return;
    }
    
    NSString *stylePath = [[styleFolder stringByAppendingPathComponent:newStyleName] stringByAppendingPathExtension:@"plist"];
    if (![plistData writeToFile:stylePath atomically:YES]) {
        NSLog(@"Failed to write to output path [%@]", stylePath);
    };
    
    _styleObjects[newStyleName] = stylePath;
}

- (void)userPreferencesChanged:(UserPreferences *)userPreferences {
    self.selectedStyleName = _styleObjects[userPreferences.styleName] ? userPreferences.styleName : CUSTOM;
}

@end
