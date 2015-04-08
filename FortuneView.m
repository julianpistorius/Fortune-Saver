//
//  PWTestView.m
//  PWTest
//
//  Created by Patrick Wallace on 27/03/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Quartz;
@import AppKit;
#import "FortuneView.h"
#import "NullAction.h"
#import "Quote.h"
#import "PreferencesWindowController.h"
#import "MoveAndFade.h"
#import "ExpandAndFade.h"

static const NSUInteger TICK_INTERVAL = 30.0;  // One 'tick' per 30 seconds.
static const NSUInteger TICKS_BEFORE_CHANGING_QUOTE = 3; // Keep each message around a couple of times in case the user didn't get a chance to read it all the first time.


@interface FortuneView () {
    CALayer         *_backgroundLayer;
    CATextLayer     *_textLayer;
    NSFont          *_textFont;
    NSFont          *_attributionFont;
    NSUInteger _ticksToChangeQuote;
    BOOL       _firstAnimation, _isPreview;
    NSString *_oldTextFontName, *_oldAttributionFontName;
    id<Transition> _moveAnimation;
    id<Transition> _textReplaceAnimation;
    
    UserPreferences *_userPreferences;
    Quotations *_allQuotes;
    PreferencesWindowController *_prefsController;
    BackgroundManager *_backgroundManager;
    FilterManager *_filterManager;
}


#pragma mark Private properties for readability.
@property (nonatomic, readonly) NSAttributedString *randomAttributedQuoteString;
@end

@implementation FortuneView

#pragma mark ScreensaverView method overrides.

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:TICK_INTERVAL]; // Note the Quartz composer uses it's own animation clock and ignores this value.
        self.wantsLayer = YES;
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
        self.layerUsesCoreImageFilters = YES;
        [self seedRandomNumberGenerator];
        
        _ticksToChangeQuote = TICKS_BEFORE_CHANGING_QUOTE;
        _userPreferences = [UserPreferences sharedPreferences];
        [_userPreferences addObserver:self];
        _firstAnimation = YES;
        _isPreview = isPreview;
        _moveAnimation = [[MoveAndFade alloc] init];
        _textReplaceAnimation = [[ExpandAndFade alloc] init];
        _backgroundManager = [BackgroundManager sharedManager];
        [_backgroundManager addObserver:self];
        _filterManager = [FilterManager sharedManager];
        [_filterManager addObserver:self];
        _allQuotes = [Quotations sharedInstance];
        
        [self createFonts];
    }
    return self;
}

- (void)createFonts {
        // Create the font we'll use for text depending if we're drawing in the preview window or the screen.
    _textFont = _attributionFont = nil;
    if (_isPreview) { // Use the default system font for the preview window.
        _textFont = [NSFont fontWithName:_userPreferences.textFont.fontName size:[NSFont systemFontSize]];
        _attributionFont = [NSFont fontWithName:_userPreferences.attributionFont.fontName size:[NSFont systemFontSize]];
    } else { // Otherwise get the font from the preferences.
        _textFont = _userPreferences.textFont;
        _attributionFont = _userPreferences.attributionFont;
    }
    _oldTextFontName = _userPreferences.textFontName;
    _oldAttributionFontName = _userPreferences.attributionFontName;
    if (!_textFont) { NSLog(@"Font %@ not found in the system preferences", _userPreferences.textFontDetails); }
    if (!_attributionFont) { NSLog(@"Font %@ not found in the system preferences", _userPreferences.attributionFontDetails); }
}

- (void)dealloc {
    [_backgroundManager removeObserver:self];
    [_filterManager removeObserver:self];
}

- (void)startAnimation {
    [super startAnimation];

    _firstAnimation = YES;
    
        // Create a sublayer and colour it.
    if (!_backgroundLayer) {
        _backgroundLayer = [self createBackgroundLayerAbove:self.layer];
    }
    if (!_textLayer) {
        _textLayer = [self createTextLayerAbove:_backgroundLayer];
    }
    
    _moveAnimation.layer = _textLayer;
    _textReplaceAnimation.layer = _textLayer;
    
    [self replaceFilter:[_filterManager filterForId:_filterManager.selectedFilterId]];
}

- (void)stopAnimation {
    [super stopAnimation];
    _moveAnimation.layer = nil;
    _textReplaceAnimation.layer = nil;
    [self removeLayers];
}

- (void)animateOneFrame {
        // Move the text layer relative to its parent each animation tick.
    BOOL showAnimation = !_firstAnimation;
    _firstAnimation = NO;
    
        // Check if we need to change the text yet.
    BOOL changeText = NO;
    _ticksToChangeQuote--;
    if (_ticksToChangeQuote == 0) {
        changeText = YES;
        _ticksToChangeQuote = TICKS_BEFORE_CHANGING_QUOTE;
    }
    [self updateTextLayerAnimated:showAnimation changeText:changeText];
}

- (BOOL)hasConfigureSheet {
    return YES;
}

- (NSWindow*)configureSheet {
    NSWindow *prefsWindow = nil;

    if (!_prefsController) {
        _prefsController = [[PreferencesWindowController alloc] init];
    }
    if (!_prefsController) { NSLog(@"PreferencesWindowController failed to load."); }
    prefsWindow = _prefsController.window;
    if (!prefsWindow) {  NSLog(@"PreferencesWindowController %@ failed to create window.", _prefsController); }
    return prefsWindow;
}

+ (BOOL)performGammaFade {
    return YES;
}


#pragma mark BackgroundManagerObserver

-(void)backgroundManagerSelectionChanged:(BackgroundManager *)manager {
    [self replaceBackgroundLayer:manager.selectedBackgroundPath];
}

#pragma mark FilterManagerObserver

- (void)filterManagerSelectionChanged:(FilterManager *)manager {
    [self replaceFilter:[manager filterForName:manager.selectedFilterName]];
}

#pragma mark UserPreferencesObserver

-(void)userPreferencesChanged:(UserPreferences *)userPreferences {
        // Just need to track the fonts here. Everything else is handled by the appropriate manager.
    BOOL updateText = !(   [userPreferences.textFontName isEqualToString:_oldTextFontName]
                        || [userPreferences.attributionFontName isEqualToString:_oldAttributionFontName]);
    if (updateText) {
     [self createFonts];
    _textLayer.string = [self randomAttributedQuoteString];
    }
}

#pragma mark Private methods.

- (void)replaceBackgroundLayer: (NSString *)newBackgroundPath {
    if (_textLayer) {
        [_textLayer removeFromSuperlayer];
        _backgroundLayer = [self createBackgroundLayerAbove:self.layer];
        [_backgroundLayer addSublayer:_textLayer];
    }
}

- (void)replaceFilter: (CIFilter *)newFilter {
    if (_textLayer) {
        _textLayer.compositingFilter = newFilter;
    }
}

- (void)seedRandomNumberGenerator {
    NSTimeInterval timeInterval = [NSDate date].timeIntervalSinceReferenceDate;
    unsigned int seedValue = timeInterval * 1000;
    srandom(seedValue);
}

    /// Create a Quartz layer which shows an animated background.
- (CALayer *) createBackgroundLayerAbove: (CALayer*)parentLayer {
    
    CALayer *backgroundLayer = nil;
    
    NSString *selectedBackgroundPath = _backgroundManager.selectedBackgroundPath;
    if (selectedBackgroundPath != nil) {
        backgroundLayer = [QCCompositionLayer compositionLayerWithFile:selectedBackgroundPath];
    }
    
    if (!backgroundLayer) {
        NSLog(@"Background layer not found or failed to load. Path = [%@]. Using default layer.", _backgroundManager.selectedBackgroundPath);
        backgroundLayer = [CALayer layer];
    }

    backgroundLayer.anchorPoint = CGPointMake(0, 0);
    backgroundLayer.bounds = self.bounds;
    backgroundLayer.position = CGPointMake(0, 0); // Relative to anchor point at bottom-left of layer.
    backgroundLayer.backgroundColor = [NSColor blackColor].CGColor;
    
    [parentLayer addSublayer:backgroundLayer];
    return backgroundLayer;
}

    /// Create a text layer with a transparent background.
- (CATextLayer *)createTextLayerAbove: (CALayer *)parentLayer {

    CATextLayer *tl = [[CATextLayer alloc] init];
    [self sizeTextLayer:tl parentBounds:self.bounds];
    [self updateTextLayerAnimated:NO changeText:YES];
    
    tl.string = [self randomAttributedQuoteString];
    tl.wrapped = YES;
    tl.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.0].CGColor; // transparent background.
    tl.anchorPoint = CGPointMake(0, 0);
    
        // Add do-nothing actions for the properties we will animate so that the layer doesn't auto-animate the changes.
    tl.actions = @{@"position" : [[NullAction alloc] init], @"opacity" : [[NullAction alloc] init], @"translation" : [[NullAction alloc] init]};
    
    [parentLayer addSublayer:tl];
    
    return tl;
}

    /// Sets the position of the text layer randomly, ensuring it will always appear on-screen. If CHANGETEXT is true, change the text while the layer is invisible. If ANIMATED is true, animate the changes.
- (void)updateTextLayerAnimated: (BOOL)animated changeText:(BOOL) changeText {
    CGPoint newPosition = CGPointMake(SSRandomFloatBetween(0.0, self.bounds.size.width  * 0.25),
                                      SSRandomFloatBetween(0.0, self.bounds.size.height * 0.5 ));
    if (animated) {
        if (changeText) {
            _textReplaceAnimation.replacementText = [self randomAttributedQuoteString];
            [_textReplaceAnimation animateToPosition:newPosition];
        } else {
            [_moveAnimation animateToPosition:newPosition];
        }
    } else {
        _textLayer.position = newPosition;
        if (changeText) {
            _textLayer.string = [self randomAttributedQuoteString];
        }
    }
}

    /// Set the size of the text layer to an appropriate amount (about 2/3 of the screen).
- (void)sizeTextLayer: (CALayer *)layer parentBounds:(CGRect)parentBounds {
    layer.bounds = CGRectMake(0, 0, parentBounds.size.width * 0.75, parentBounds.size.height * 0.5);
}

    /// Remove and destroy the CA Layers we created.  We will recreate them next time the view is displayed.
- (void) removeLayers {
    if (_textLayer) {
        [_textLayer removeFromSuperlayer];
        _textLayer = nil;
    }
    if (_backgroundLayer) {
        [_backgroundLayer removeFromSuperlayer];
        _backgroundLayer = nil;
    }
}

    /// Create and return a random attributed string containing the text and attributions in their appropriate colours.
- (NSAttributedString *)randomAttributedQuoteString {
    Quote *quote = _allQuotes.randomQuote;
    NSString *fullTextString = [NSString stringWithFormat:@"%@\n", quote.text];
    NSDictionary *textStringAttributes = @{ NSFontAttributeName : _textFont,
                                            NSForegroundColorAttributeName : _userPreferences.textColour };
    
    NSMutableAttributedString *quoteString = [[NSMutableAttributedString alloc] initWithString:fullTextString attributes:textStringAttributes];
    
    if (quote.attribution.length > 0) {
        NSDictionary *attributionStringAttributes = @{NSFontAttributeName : _attributionFont,
                                                      NSForegroundColorAttributeName : _userPreferences.attributionColour };
        NSString *fullAttributionString = [NSString stringWithFormat:@"\t—%@", quote.attribution];
        NSAttributedString *attributionString = [[NSAttributedString alloc] initWithString:fullAttributionString attributes:attributionStringAttributes];
        [quoteString appendAttributedString:attributionString];
    }
    return quoteString;
}

@end
