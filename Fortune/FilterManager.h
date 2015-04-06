//
//  FilterManager.h
//  Fortune
//
//  Created by Patrick Wallace on 06/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Cocoa;


@class FilterManager;

    /// Observer
@protocol FilterManagerObserver <NSObject>

    /// Called when the preferences indicate that the filter selection has changed. The delegate should redraw the screen or change the selection on a menu item.
- (void)filterManagerSelectionChanged: (FilterManager*) manager;

@end





@interface FilterManager : NSObject

    /// Return the instance which is shared between all users.
+ (instancetype) sharedManager;

#pragma mark -

    /// Array of strings to use for a list of backgrounds. Human-readable.
@property (nonatomic, readonly) NSArray *filterNames;

    /// The ID of the selected filter. Conventience method. Returns the ID of the filter selected by the name.
@property (nonatomic, readonly) NSString *selectedFilterId;

    /// The readable name of a filter stored in filterNames. Use to keep track of the selection between objects.
@property (nonatomic, strong) NSString *selectedFilterName;

    /// The special name of the NONE filter in the first position of the filters menu.
@property (nonatomic, readonly) NSString *filterNameNone;

#pragma mark - Methods

    /// Given one of the IDs in filterIds, return a Core Image filter it represents.
- (CIFilter *)filterForId: (NSString *)filterId;

#pragma mark Observer

- (void)addObserver: (id<FilterManagerObserver>)observer;
- (void)removeObserver: (id<FilterManagerObserver>)observer;

@end
