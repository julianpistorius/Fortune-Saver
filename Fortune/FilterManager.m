//
//  FilterManager.m
//  Fortune
//
//  Created by Patrick Wallace on 06/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import QuartzCore;
#import "FilterManager.h"
#import "UserPreferences.h"

@interface FilterManager () {
        // Key = Filter Name, value = Filter ID
    NSDictionary *_filterObjects; // NSString -> NSString
    UserPreferences *_userPreferences;
    NSMutableArray *_observers;  // id<FilterManagerObserver>
}

@end

static FilterManager *singleton = nil;

@implementation FilterManager
@synthesize selectedFilterName = _selectedFilterName;

#pragma mark Housekeeping methods

+ (instancetype)sharedManager {
    if (!singleton) {
        singleton = [[FilterManager alloc] init];
    }
    return singleton;
}


- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }
    
    _userPreferences = [UserPreferences sharedPreferences];
    NSString *defaultFilterName = _userPreferences.filterName;
    _observers = [NSMutableArray array];
    
        // Load all the filter IDs into the dictionary.
    _filterObjects = [self loadFilterNames];
    if (_filterObjects.count == 0) {
        NSLog(@"Couldn't find any filters in category %@", kCICategoryCompositeOperation);
    }
    
        // If the filter from the Preferences is present, then select it here.
    if ([_filterObjects objectForKey:defaultFilterName] != nil) {
        _selectedFilterName = defaultFilterName;
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


#pragma mark Private methods

- (NSDictionary *)loadFilterNames {
    NSMutableDictionary *items = [NSMutableDictionary dictionary];
    for (NSString *filterName in [CIFilter filterNamesInCategory:kCICategoryCompositeOperation]) {
        NSString *title = [self titleFromCIFilterName:filterName];
        [items setObject:filterName forKey:title];
    }
    return items;
}

    // Make a human-readable title based on the encoded filter Id.
- (NSString *)titleFromCIFilterName: (NSString*)filterName {
    NSString *filterTitle = filterName;
    NSString *const CI = @"CI", *const MODE = @"Mode", *const COMPOSITING = @"Compositing";
    
        // Remove the CI prefix from the start of the string.
    if ([filterTitle hasPrefix:CI]) {
        filterTitle = [filterTitle substringFromIndex:CI.length];
    }
        // Remove the words "Compositing" and "Mode" from the end of the title.
    if ([filterTitle hasSuffix:MODE]) {
        filterTitle = [filterTitle substringToIndex:filterTitle.length - MODE.length];
    }
    if ([filterTitle hasSuffix:COMPOSITING]) {
        filterTitle = [filterTitle substringToIndex:filterTitle.length - COMPOSITING.length];
    }
    
        // Now insert a space before each capital letter.
    NSMutableString *result = [NSMutableString string];
    NSCharacterSet *uppercaseCharSet = [NSCharacterSet uppercaseLetterCharacterSet];
    for (NSUInteger i = 0, c = filterTitle.length; i < c; i++) {
        unichar character = [filterTitle characterAtIndex:i];
        if ([uppercaseCharSet characterIsMember:character] && result.length > 0) {
            [result appendString:@" "];
        }
        NSString *newString = [NSString stringWithCharacters:&character length:1];
        [result appendString:newString];
    }
    filterTitle = result;
    return filterTitle;
}

#pragma mark Property implementations

    // This updates the global preferences. When you respond to a preferences change don't use this method, assign to _selectedFilter directly.
- (void)setSelectedFilterName:(NSString *)selectedFilterId {
    if (![_selectedFilterName isEqualToString:selectedFilterId]) {
        _selectedFilterName = selectedFilterId;
        
        for (id<FilterManagerObserver> observer in _observers) {
            [observer filterManagerSelectionChanged:self];
        }
            // Update the global preferences with the new value.
        _userPreferences.filterName = selectedFilterId;
    }
}

- (NSString *)selectedFilterId {
    return _selectedFilterName ? [_filterObjects valueForKey:_selectedFilterName] : nil;
}

-(NSArray *)filterNames {
        // Add the null filter name "None" at the start of the list.
    NSMutableArray *names = [NSMutableArray arrayWithObject:self.filterNameNone];
    [names addObjectsFromArray:_filterObjects.allKeys];
    return names;
}

- (NSString *)filterNameNone {
    return @"None";
}

#pragma mark Public Methods

- (CIFilter *)filterForName:(NSString *)filterName {
    NSString *filterId = _filterObjects[filterName];
    return [self filterForId:filterId];
}


- (CIFilter *)filterForId:(NSString *)filterId {
    CIFilter *result = nil;
    if (filterId) {
        result = [CIFilter filterWithName:filterId];
    }
    return result;
}

#pragma mark Observers

- (void)addObserver:(id<FilterManagerObserver>)observer {
    if (![_observers containsObject:observer]) {
        [_observers addObject:observer];
    }
}

- (void)removeObserver:(id<FilterManagerObserver>)observer {
    [_observers removeObjectIdenticalTo:observer];
}

- (void)preferenceChanged: (NSNotification *)notification {
    if (![_userPreferences.filterName isEqualToString:self.selectedFilterName]) {
            // Change the filter directly. Don't use the property as that updates the preferences and leads to an infinite loop.
        _selectedFilterName = _userPreferences.filterName;
    }
}


@end
