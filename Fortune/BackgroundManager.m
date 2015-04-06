//
//  BackgroundManager.m
//  Fortune
//
//  Created by Patrick Wallace on 05/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "BackgroundManager.h"

@interface BackgroundManager () {
        // Key = name, value = full path to the file.
    NSDictionary *_backgroundObjects;
    UserPreferences *_userPreferences;
    NSMutableArray *_observers;
}
@property (nonatomic, readonly) NSString *backgroundBlack;
@end

static BackgroundManager *singleton = nil;

@implementation BackgroundManager
@synthesize selectedBackground = _selectedBackground;

+ (instancetype)sharedManager {
    if (!singleton) {
        singleton = [[BackgroundManager alloc] init];
    }
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }
    
    _userPreferences = [UserPreferences sharedPreferences];
    [_userPreferences addObserver:self];
    
    _observers = [NSMutableArray array];
    
    [self reload];

    return self;
}

- (void)dealloc {
    [_userPreferences removeObserver:self];
}

- (NSString *)backgroundBlack {
    return @"Black";
}

- (void)reload {
    _backgroundObjects = [self loadBackgrounds];
        // Update the selected background to match the one loaded from the preferences.
    NSString *defaultBackground = _userPreferences.backgroundName;
    if (_backgroundObjects[defaultBackground]) {
        self.selectedBackground = defaultBackground;
    }
}

    /// Load all the backgrounds into the dictionary.
- (NSDictionary *)loadBackgrounds {
    NSMutableDictionary *backgroundObjects = [NSMutableDictionary dictionary];
    NSBundle *ourBundle = [NSBundle bundleForClass:self.class];
    for (NSString *backgroundAnimation in [ourBundle pathsForResourcesOfType:@"qtz" inDirectory:@"Backgrounds"]) {
        NSString *title = backgroundAnimation.stringByDeletingPathExtension.lastPathComponent;
        backgroundObjects[title] = backgroundAnimation;
    }
    if (backgroundObjects.count == 0) {
        NSLog(@"Couldn't find any backgrounds in bundle %@", ourBundle);
    }
    return backgroundObjects;
}

    /// Array of strings to use for a list of backgrounds.
- (NSArray *)backgroundNames {
    return _backgroundObjects.allKeys;
}

    /// Given one of the names in backgroundNames, return the full path to that file.
- (NSString *)pathForName: (NSString *)backgroundName {
    return _backgroundObjects[backgroundName];
}

- (NSString *)selectedBackground { return _selectedBackground; }

    // This updates the global preferences. When you respond to a preferences change don't use this method, assign to _selectedBackground directly.
- (void)setSelectedBackground:(NSString *)selectedBackground {
    if (![_selectedBackground isEqualToString:selectedBackground]) {
        _selectedBackground = selectedBackground;
        
        for (id<BackgroundManagerObserver> observer in _observers) {
            [observer backgroundManagerSelectionChanged:self];
        }
            // Update the global preferences with the new value.
        _userPreferences.backgroundName = selectedBackground;
    }
}

- (NSString *)selectedBackgroundPath {
    return [self pathForName:self.selectedBackground];
}

- (void)addObserver:(id<BackgroundManagerObserver>)observer {
    if (![_observers containsObject:observer]) {
        [_observers addObject:observer];
    }
}

- (void)removeObserver:(id<BackgroundManagerObserver>)observer {
    [_observers removeObjectIdenticalTo:observer];
}

- (void)userPreferencesChanged: (UserPreferences*)userPreferences {
    self.selectedBackground = _backgroundObjects[userPreferences.backgroundName] ? userPreferences.backgroundName : self.backgroundBlack;
}

@end
