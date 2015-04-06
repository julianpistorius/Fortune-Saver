//
//  StyleManager.h
//  Fortune
//
//  Created by Patrick Wallace on 06/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserPreferences.h"

@interface StyleManager : NSObject <UserPreferencesObserver>

    /// Returns a pointer to the single instance of this manager.
+ (instancetype)sharedManager;

    /// An array of NSString objects representing all the style names available.
@property (nonatomic, readonly) NSArray *styleNames;

    /// The currently-selected style.
@property (nonatomic, strong) NSString *selectedStyleName;

    /// Name of the special "Custom" style.
@property (nonatomic, readonly) NSString *customStyleName;

    /// Applies the specified style, which will update the user defaults and trigger other notifications.
- (void)applyStyleNamed: (NSString*)styleName;

    /// True if a style already exists with the given style name, false otherwise.
- (BOOL)styleExists: (NSString *)styleName;

    /// Save a new style into the bundle with name 'newStyleName' and the current settings.
- (void)addStyle: (NSString *)newStyleName;

    /// Refresh the data from the preferences, undoing any changes the user may have made.
- (void)reload;

@end
