//
//  FilterManager.m
//  Fortune
//
//  Created by Patrick Wallace on 06/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import QuartzCore;
#import "FilterManager.h"

@interface FilterManager () {
        // Key = Filter Name, value = Filter ID
    NSDictionary *_filterObjects; // NSString -> NSString
    UserPreferences *_userPreferences;
    NSMutableArray *_observers;  // id<FilterManagerObserver>
}
    /// The special name of the NONE filter in the first position of the filters menu.
@property (nonatomic, readonly) NSString *filterNameNone;

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
    [_userPreferences addObserver:self];
    _observers = [NSMutableArray array];
    
    [self reload];

    return self;
}

- (void)dealloc {
    [_userPreferences removeObserver:self];
}


- (void)reload {
        // Load all the filter IDs into the dictionary.
    _filterObjects = [self loadFilterNames];
    if (_filterObjects.count == 0) {
        NSLog(@"Couldn't find any filters in category %@", kCICategoryCompositeOperation);
    }
    
        // If the filter from the Preferences is present, then select it here.
    NSString *defaultFilterName = _userPreferences.filterName;
    if ([_filterObjects objectForKey:defaultFilterName] != nil) {
        self.selectedFilterName = defaultFilterName;
    }
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

    // Returns the selected filter name, or none if it is nil.
- (NSString *)selectedFilterName {
    return _selectedFilterName ? _selectedFilterName : self.filterNameNone;
}

    // This updates the global preferences. When you respond to a preferences change don't use this method, assign to _selectedFilter directly.
- (void)setSelectedFilterName:(NSString *)filterName {
    if (![_selectedFilterName isEqualToString:filterName]) {
        _selectedFilterName = filterName;

            // Update the global preferences with the new value.
        _userPreferences.filterName = filterName;
        
        for (id<FilterManagerObserver> observer in _observers) {
            [observer filterManagerSelectionChanged:self];
        }
    }
}

- (NSString *)selectedFilterId {
    if (!_selectedFilterName) { return nil; }
    if ([_selectedFilterName isEqualToString:self.filterNameNone]) { return nil; }
    return _filterObjects[_selectedFilterName];
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
    if ([filterName isEqualToString:self.filterNameNone]) { return nil; }
    
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

- (void)userPreferencesChanged:(UserPreferences *)userPreferences {
    NSString *filterName = userPreferences.filterName;
    if (!filterName) {
        filterName = self.filterNameNone;
    }
    self.selectedFilterName = _filterObjects[userPreferences.filterName] ? userPreferences.filterName : self.filterNameNone;
}



@end
