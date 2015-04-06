//
//  PreferencesWindowController.m
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "UserPreferences.h"
#import "BackgroundManager.h"


typedef NS_ENUM(NSUInteger, FontSelectState) {
    NOT_SELECTING_FONT,
    SELECTING_TEXT_FONT,
    SELECTING_ATTRIBUTION_FONT
};

@interface PreferencesWindowController () {
        // Styles button. Allows the user to select pre-defined styles.
    __weak IBOutlet NSPopUpButton *stylesButton;
    
        // If the style is Custom, these buttons allow the user to select specific items.
    __weak IBOutlet NSColorWell *textColour;
    __weak IBOutlet NSColorWell *attributionColour;
    __weak IBOutlet NSButton *textFontButton;
    __weak IBOutlet NSButton *attributionFontButton;
    __weak IBOutlet NSPopUpButton *backgroundsButton;
    __weak IBOutlet NSPopUpButton *filtersButton;
    
    NSFont *_selectedTextFont, *_selectedAttributionFont;
    FontSelectState _fontSelectState;
    
    BackgroundManager *_backgroundManager;
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

-(instancetype)init {
    NSWindow *loadedNib = loadNib(self);
    self = [super initWithWindow:loadedNib];
    if (!self) {
        return nil;
    }
    _userPreferences = [UserPreferences sharedPreferences];
    _fontSelectState = NOT_SELECTING_FONT;
    _backgroundManager = [BackgroundManager sharedManager];
    [_backgroundManager addObserver:self];
    
    [self windowDidLoad];
    return self;
}

- (void)dealloc {
    [_backgroundManager removeObserver:self];
}

- (BOOL)acceptsFirstResponder {
    return YES; // We want to receive menu item events.
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self populateBackgroundsButton];
    [self populateStylesButton];
    [self populateFiltersButton];
    
    [self loadPreferences];
}

- (void)loadPreferences {
    textColour.color = self.userPreferences.textColour;
    attributionColour.color = self.userPreferences.attributionColour;
    [self setTextInButton:textFontButton forFont:self.userPreferences.textFont];
    [self setTextInButton:attributionFontButton forFont:self.userPreferences.attributionFont];
    
    [backgroundsButton selectItemWithTitle:_backgroundManager.selectedBackground];
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
    
    if (backgroundsButton.selectedItem.title) {
        _backgroundManager.selectedBackground = backgroundsButton.selectedItem.title;
    }
    
    [self.userPreferences synchronise];
}

#pragma mark Font Management

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

#pragma mark Interface Builder Actions

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


#pragma mark Button menu support

- (void)populateBackgroundsButton {
    [backgroundsButton removeAllItems];
    [backgroundsButton addItemsWithTitles:_backgroundManager.backgroundNames];
    if (_backgroundManager.selectedBackground) {
        [backgroundsButton selectItemWithTitle:_backgroundManager.selectedBackground];
    }
}

- (void)populateStylesButton {
    [stylesButton removeAllItems];
    [stylesButton addItemWithTitle:@"Green & Gold"];
    [stylesButton addItemWithTitle:@"Custom"];
    [stylesButton selectItemAtIndex:1];
}

- (void)populateFiltersButton {
    [filtersButton removeAllItems];
    [filtersButton addItemWithTitle:@"TODO"];
    [filtersButton selectItemAtIndex:0];
}

    // TODO: Enable/Disable values based on popup button menu selection.
- (void)styleChanged: (NSMenuItem *)sender {
    BOOL customEnabled = [sender.title isEqualToString:@"Custom"];
    backgroundsButton.enabled = filtersButton.enabled = textColour.enabled = attributionColour.enabled = textFontButton.enabled = attributionFontButton.enabled = customEnabled;
}

    /// Called when the current selected background changes. Update the button states to match.
- (void)backgroundManagerSelectionChanged:(BackgroundManager *)manager {
    [backgroundsButton selectItemWithTitle:manager.selectedBackground];
}


@end
