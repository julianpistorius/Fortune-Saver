//
//  PreferencesWindowController.m
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "UserPreferences.h"
#import "StyleManager.h"


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
    __weak IBOutlet NSPathControl *documentURLButton;
    
    NSFont *_selectedTextFont, *_selectedAttributionFont;
    FontSelectState _fontSelectState;
    
#ifdef DEBUG
    BOOL _removeAllPreferences;
#endif
    
    BackgroundManager *_backgroundManager;
    FilterManager *_filterManager;
    StyleManager *_styleManager;
}
@property (nonatomic, readonly) UserPreferences *userPreferences;

- (IBAction)changeTextFont:(NSButton *)sender;
- (IBAction)changeAttributionFont:(NSButton *)sender;
- (IBAction)changeStyle:(NSPopUpButton *)sender;
@end


@implementation PreferencesWindowController

static NSWindow * loadNib(id owner) {
    NSArray *nibObjects;
    NSBundle *saverBundle = [NSBundle bundleForClass:[PreferencesWindowController class]];
    NSNib *prefsNib = [[NSNib alloc] initWithNibNamed:@"PreferencesPanel" bundle:saverBundle];
    [prefsNib instantiateWithOwner:owner topLevelObjects:&nibObjects];
    if(!(nibObjects && nibObjects.count > 0)) { NSLog(@"failed to load nib from main bundle."); }

    NSPanel *prefsPanel = nil;
    for (id nibObject in nibObjects) {
        if ([nibObject isMemberOfClass:[NSPanel class]]) {
            prefsPanel = nibObject;
        }
    }
    if(!prefsPanel) { NSLog(@"prefsPanel not found in the nib."); }
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
    _filterManager = [FilterManager sharedManager];
    [_filterManager addObserver:self];
    _styleManager = [StyleManager sharedManager];
    
    NSNotificationCenter *notificationCentre = [NSNotificationCenter defaultCenter];
    [notificationCentre addObserver:self selector:@selector(windowWillBeginSheet:) name:NSWindowWillBeginSheetNotification object:nil];
    
#ifdef DEBUG
    _removeAllPreferences = NO;
#endif
    
    return self;
}

- (void)dealloc {
    [_backgroundManager removeObserver:self];
    [_filterManager removeObserver:self];
    NSNotificationCenter *defaultCentre = [NSNotificationCenter defaultCenter];
    [defaultCentre removeObserver:self];
}

- (BOOL)acceptsFirstResponder {
    return YES; // We want to receive menu item events.
}

- (void)windowWillBeginSheet: (NSNotification*)notification {

#ifdef DEBUG
    _removeAllPreferences = NO;
#endif

    [self populateBackgroundsButton];
    [self populateStylesButton];
    [self populateFiltersButton];
    
        // Tell the global colour preferences window we want to include alpha-blending.
    [NSColorPanel sharedColorPanel].showsAlpha = YES;
    
    [self loadPreferences];
}

- (void)loadPreferences {
    textColour.color = self.userPreferences.textColour;
    attributionColour.color = self.userPreferences.attributionColour;
    _selectedTextFont = self.userPreferences.textFont;
    [self setTextInButton:textFontButton forFont:_selectedTextFont];
    _selectedAttributionFont = self.userPreferences.attributionFont;
    [self setTextInButton:attributionFontButton forFont:_selectedAttributionFont];
    
    [backgroundsButton selectItemWithTitle:_backgroundManager.selectedBackground];
    
    NSString *selectedFilter = _filterManager.selectedFilterName;
    [filtersButton selectItemWithTitle:selectedFilter];
    [stylesButton selectItemWithTitle:_styleManager.selectedStyleName];
    
    documentURLButton.URL = self.userPreferences.quotesFileURL;
}


- (void)savePreferences {
#ifdef DEBUG
    if (_removeAllPreferences) {
        [self.userPreferences removeAll];
        [self.userPreferences synchronise];
        return;
    }
#endif
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
    if (filtersButton.selectedItem.title) {
        _filterManager.selectedFilterName = filtersButton.selectedItem.title;
    }
    
    if (stylesButton.selectedItem.title) {
        _styleManager.selectedStyleName = stylesButton.selectedItem.title;
    }
    
    self.userPreferences.quotesFileURL = documentURLButton.URL;
    
    [self.userPreferences synchronise];
}

#pragma mark Font Management

- (void)setTextInButton: (NSButton*)button forFont: (NSFont *)font {
    NSString *title = [NSString stringWithFormat:@"%@ %lu", (font.displayName ? font.displayName : font.fontName), (NSUInteger)font.pointSize];
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
            NSLog(@"changeFont: called with invalid state %lu", _fontSelectState);
            break;
    }
}

    // Do-nothing method sent by the font manager to tell large text fields with embedded attributes that they need to change.
- (void)changeAttributes:(NSFontManager *)sender {
}

#pragma mark Interface Builder Actions

- (IBAction) closePreferencesPane: (id)sender {
        // Hide the font and colour panels if they are currently displayed.
    if ([NSFontPanel sharedFontPanelExists]) {
        [[NSFontPanel sharedFontPanel] orderOut:self];
    }
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] orderOut:self];
    }
    [self savePreferences];
    [[NSApplication sharedApplication] endSheet:self.window];
}

- (IBAction)changeTextFont:(NSButton *)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    fontManager.target = self;
    _fontSelectState = SELECTING_TEXT_FONT;
    _selectedTextFont = self.userPreferences.textFont;
    [fontManager setSelectedFont:_selectedTextFont isMultiple:NO];
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel makeKeyAndOrderFront:self];
}

- (IBAction)changeAttributionFont:(NSButton *)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    fontManager.target = self;
    _fontSelectState = SELECTING_ATTRIBUTION_FONT;
    _selectedAttributionFont = self.userPreferences.attributionFont;
    [fontManager setSelectedFont:_selectedAttributionFont isMultiple:NO];
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel makeKeyAndOrderFront:self];
}

- (IBAction)changeStyle:(NSPopUpButton *)sender {
    BOOL customEnabled = [sender.title isEqualToString:_styleManager.customStyleName];
    backgroundsButton.enabled = filtersButton.enabled = textColour.enabled = attributionColour.enabled = textFontButton.enabled = attributionFontButton.enabled = customEnabled;
    if (!customEnabled) {
        [_styleManager applyStyleNamed:sender.title];
        [self loadPreferences]; // Reinitialize the GUI from the updated preferences.
    }
}

#ifdef DEBUG
    /// If the user clicks the + button next to the style list, this copies the current settings into a new style object.
    /// This is for debug only -currently the only style directory is in the bundle which will be overwritten whenever we update the screensaver.
    /// So this is for development use only.
- (IBAction)addStyle:(NSButton *)sender {
    NSString *newStyleName = nil;
    for (NSUInteger i = 1, c = 100; i < c; i++) {
        NSString *newName = [NSString stringWithFormat:@"User Style %0.2lu", (unsigned long)i];
        if (![_styleManager styleExists: newStyleName]) {
            newStyleName = newName;
            break;
        }
    }
    
    if (!newStyleName) {
        NSLog(@"Couldn't allocate a new style. Do we have 99 user styles already?");
        return;
    }
    
    [self savePreferences];
    [_styleManager addStyle:newStyleName];
    _styleManager.selectedStyleName = newStyleName;
    [self populateStylesButton];
}

    /// Another use for the + button during development. Remove all values from the user defaults so that I can see what it looks like on a clean startup.
- (IBAction)removeAllPreferences:(NSButton *)sender {
    _removeAllPreferences = YES;
}
#endif

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
    [stylesButton addItemsWithTitles:_styleManager.styleNames];
    if (_styleManager.selectedStyleName) {
        [stylesButton selectItemWithTitle:_styleManager.selectedStyleName];
    }
}

- (void)populateFiltersButton {
    [filtersButton removeAllItems];
    [filtersButton addItemsWithTitles:_filterManager.filterNames];
    if (_filterManager.selectedFilterName) {
        [filtersButton selectItemWithTitle:_filterManager.selectedFilterName];
    }
}

#pragma mark BackgroundManager Observer

    /// Called when the current selected background changes. Update the button states to match.
- (void)backgroundManagerSelectionChanged:(BackgroundManager *)manager {
    [backgroundsButton selectItemWithTitle:manager.selectedBackground];
}

#pragma mark FilterManager Observer

-(void)filterManagerSelectionChanged:(FilterManager *)manager {
    [filtersButton selectItemWithTitle:manager.selectedFilterName];
}

@end
