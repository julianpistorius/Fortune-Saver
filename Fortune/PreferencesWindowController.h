//
//  PreferencesWindowController.h
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Cocoa;
#import "BackgroundManager.h"

@class UserPreferences;

@interface PreferencesWindowController : NSWindowController <NSMenuDelegate, BackgroundManagerObserver>

- (instancetype)init; //NS_DESIGNATED_INITIALIZER;

@end
