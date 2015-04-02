//
//  PreferencesWindowController.m
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "UserPreferences.h"


NS_ENUM(NSUInteger, FontSelectState) {
    NOT_SELECTING_FONT,
    SELECTING_TEXT_FONT,
    SELECTING_ATTRIBUTION_FONT
};

@interface PreferencesWindowController () {
    __weak IBOutlet NSColorWell *textColour;
    __weak IBOutlet NSColorWell *attributionColour;
    __weak IBOutlet NSButton *textFontButton;
    __weak IBOutlet NSButton *attributionFontButton;
    
    NSFont *_selectedTextFont, *_selectedAttributionFont;
    enum FontSelectState _fontSelectState;
}
@property (nonatomic, readonly) UserPreferences *userPreferences;

- (IBAction)changeTextFont:(NSButton *)sender;
- (IBAction)changeAttributionFont:(NSButton *)sender;

@end


@implementation PreferencesWindowController
@synthesize userPreferences = _userPreferences;

static NSWindow * loadNib(id owner) {
    NSArray *nibObjects;
    NSBundle *saverBundle = [NSBundle bundleForClass:[PreferencesWindowController class]];
    NSNib *prefsNib = [[NSNib alloc] initWithNibNamed:@"PreferencesPanel" bundle:saverBundle];
    [prefsNib instantiateWithOwner:owner topLevelObjects:&nibObjects];
    NSCAssert(nibObjects && nibObjects.count > 0, @"failed to load nib from main bundle.");

    NSPanel *prefsPanel = nil;
    for (id nibObject in nibObjects) {
        if ([nibObject isMemberOfClass:[NSPanel class]]) {
            prefsPanel = nibObject;
        }
    }
    NSCAssert(prefsPanel, @"prefsPanel not found in the nib.");
    return prefsPanel;
}

-(instancetype)initWithUserPreferences:(UserPreferences *)prefs {
    NSWindow *loadedNib = loadNib(self);
    self = [super initWithWindow:loadedNib];
    if (!self) {
        return nil;
    }
//    self = [super initWithWindowNibName:@"PreferencesPanel"];
//    if (!self) return nil;
    _userPreferences = prefs;
    _fontSelectState = NOT_SELECTING_FONT;
    _selectedAttributionFont = _selectedTextFont = nil;
    
    [self windowDidLoad];
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self loadPreferences];
    
}

- (void)loadPreferences {
    textColour.color = self.userPreferences.textColour;
    attributionColour.color = self.userPreferences.attributionColour;
    [self setTextInButton:textFontButton forFont:self.userPreferences.textFont];
    [self setTextInButton:attributionFontButton forFont:self.userPreferences.attributionFont];
}



- (void)savePreferences {
    [self.userPreferences setTextColour:textColour.color];
    [self.userPreferences setAttributionColour:attributionColour.color];
    
    if (_selectedTextFont) {
        self.userPreferences.textFont = _selectedTextFont;
    }
    if (_selectedAttributionFont) {
        self.userPreferences.attributionFont = _selectedAttributionFont;
    }
    [self.userPreferences synchronise];
}

- (void)setTextInButton: (NSButton*)button forFont: (NSFont *)font {
    NSString *title = [NSString stringWithFormat:@"%@ %lu pt", font.fontName, (NSUInteger)font.pointSize];
    button.title = button.alternateTitle = title;
}

- (void)changeFont:(NSFontManager *)sender {
    switch (_fontSelectState) {
        case SELECTING_TEXT_FONT:
            _selectedTextFont = [sender convertFont:_selectedTextFont];
            [self setTextInButton:textFontButton forFont:_selectedTextFont];
            break;
        case SELECTING_ATTRIBUTION_FONT:
            _selectedAttributionFont = [sender convertFont:_selectedAttributionFont];
            [self setTextInButton:attributionFontButton forFont:_selectedAttributionFont];
            break;
        default:
            NSAssert(NO, @"changeFont: called with invalid state %lu", _fontSelectState);
            break;
    }
}

#pragma mark - Interface Builder Actions

- (IBAction) closePreferencesPane: (id)sender {
    [self savePreferences];
    [[NSApplication sharedApplication] endSheet:self.window];
}

- (IBAction)changeTextFont:(NSButton *)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    fontManager.target = self;
    _fontSelectState = SELECTING_TEXT_FONT;
    _selectedTextFont = self.userPreferences.textFont;
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel makeKeyAndOrderFront:self];
}

- (IBAction)changeAttributionFont:(NSButton *)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    fontManager.target = self;
    _fontSelectState = SELECTING_ATTRIBUTION_FONT;
    _selectedAttributionFont = self.userPreferences.attributionFont;
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel makeKeyAndOrderFront:self];
}


@end
