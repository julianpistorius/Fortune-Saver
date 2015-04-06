//
//  BackgroundManager.m
//  Fortune
//
//  Created by Patrick Wallace on 05/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "BackgroundManager.h"
#import "UserPreferences.h"

@interface BackgroundManager () {
        // Key = name, value = full path to the file.
    NSDictionary *_backgroundObjects;
    UserPreferences *_userPreferences;
    NSMutableArray *_observers;
}

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
    NSString *defaultBackground = _userPreferences.backgroundName;
    _observers = [NSMutableArray array];
    
        // Load all the backgrounds into the dictionary.
    _backgroundObjects = [NSMutableDictionary dictionary];
    NSBundle *ourBundle = [NSBundle bundleForClass:self.class];
    for (NSString *backgroundAnimation in [ourBundle pathsForResourcesOfType:@"qtz" inDirectory:@"Backgrounds"]) {
        NSString *title = backgroundAnimation.stringByDeletingPathExtension.lastPathComponent;
        [_backgroundObjects setValue:backgroundAnimation forKey:title];
        
            // If we find the background in the preferences, then set it as selected here.  If it has been removed then leave the selected flag as nil.
        if ([title isEqualToString:defaultBackground]) {
            _selectedBackground = defaultBackground;
        }
    }
    if (_backgroundObjects.count == 0) {
        NSLog(@"Couldn't find any backgrounds in bundle %@", ourBundle);
    }
    
        // register for preference change notifications.
    NSNotificationCenter *notificationCentre = [NSNotificationCenter defaultCenter];
    [notificationCentre addObserver:self selector:@selector(preferenceChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCentre = [NSNotificationCenter defaultCenter];
    [notificationCentre removeObserver:self];
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

- (void)preferenceChanged: (NSNotification *)notification {
    if (![_userPreferences.backgroundName isEqualToString:self.selectedBackground]) {
            // Change the background directly. Don't use the property as that updates the preferences and leads to an infinite loop.
        _selectedBackground = _userPreferences.backgroundName;
    }
}

@end
