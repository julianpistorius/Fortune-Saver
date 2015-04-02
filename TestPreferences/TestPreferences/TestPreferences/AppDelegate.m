//
//  AppDelegate.m
//  TestPreferences
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "AppDelegate.h"
#import "UserPreferences.h"
#import "PreferencesWindowController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@interface AppDelegate () {
    PreferencesWindowController *_prefsController;
    UserPreferences *_userPreferences;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)showPreferences:(id)sender {
    if (!_userPreferences) {
        _userPreferences = [[UserPreferences alloc] init];
    }
    if (!_prefsController) {
        _prefsController = [[PreferencesWindowController alloc] initWithUserPreferences:_userPreferences];
    }
    NSPanel *prefsPanel = (NSPanel *)_prefsController.window;
    [self.window beginSheet:prefsPanel
          completionHandler:^(NSModalResponse returnCode) {}];
}

@end
