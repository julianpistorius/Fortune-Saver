//
//  PreferencesWindowController.h
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Cocoa;
@class UserPreferences;

@interface PreferencesWindowController : NSWindowController

- (instancetype)initWithUserPreferences: (UserPreferences *)userPreferences;

@end
