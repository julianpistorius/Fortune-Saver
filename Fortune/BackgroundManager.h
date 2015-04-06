//
//  BackgroundManager.h
//  Fortune
//
//  Created by Patrick Wallace on 05/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BackgroundManager;

    /// Observer
@protocol BackgroundManagerObserver <NSObject>

    /// Called when the preferences indicate that the background selection has changed. The delegate should redraw the screen or change the selection on a menu item.
- (void)backgroundManagerSelectionChanged: (BackgroundManager*) manager;

@end

@interface BackgroundManager : NSObject

    /// Return the instance which is shared between all users.
+ (instancetype) sharedManager;

#pragma mark -

    /// Array of strings to use for a list of backgrounds.
@property (nonatomic, readonly) NSArray *backgroundNames;

    /// The name of the selected background. Use to keep track of the selection between objects.
@property (nonatomic, strong) NSString *selectedBackground;

    /// Convenience property. Get the full path of whatever name is set in selectedBackground.
@property (nonatomic, readonly) NSString *selectedBackgroundPath;

#pragma mark - Methods

    /// Given one of the names in backgroundNames, return the full path to that file.
- (NSString *)pathForName: (NSString *)backgroundName;

#pragma mark Observer

- (void)addObserver: (id<BackgroundManagerObserver>)object;
- (void)removeObserver: (id<BackgroundManagerObserver>)object;
@end
