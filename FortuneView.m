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
#import "UserPreferences.h"
#import "Quote.h"
#import "PreferencesWindowController.h"

static const NSUInteger TICK_INTERVAL = 30.0;  // One 'tick' per 30 seconds.
static const NSUInteger TICKS_BEFORE_CHANGING_QUOTE = 2 * 10; // Each tick is 30 seconds, so this is 10 minutes.


@interface FortuneView () {
    CALayer         *_backgroundLayer;
    CATextLayer     *_textLayer;
    NSArray         *_allQuotes;  // Of type Quote
    NSFont          *_textFont;
    NSFont          *_attributionFont;
    UserPreferences *_userPreferences;
    NSTimer         *_restoreTimer;
    NSUInteger _ticksToChangeQuote;
    BOOL       _firstAnimation;
    
    PreferencesWindowController *_prefsController;
}


#pragma mark Private properties for readability.
@property (nonatomic, readonly) Quote *randomQuote;
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
        _userPreferences = [[UserPreferences alloc] init];
        _firstAnimation = YES;
        
            // Create the font we'll use for text depending if we're drawing in the preview window or the screen.
        _textFont = _attributionFont = nil;
        if (isPreview) { // Use the default system font for the preview window.
            _textFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
            _attributionFont = _textFont;
        } else { // Otherwise get the font from the preferences.
            _textFont = _userPreferences.textFont;
            _attributionFont = _userPreferences.attributionFont;
        }
        NSAssert(_textFont, @"Font %@ not found in the system preferences", _userPreferences.textFontDetails);
        NSAssert(_attributionFont, @"Font %@ not found in the system preferences", _userPreferences.attributionFontDetails);
    }
    return self;
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
}

- (void)stopAnimation {
    [super stopAnimation];
    [self removeLayers];
}

- (void)animateOneFrame {
        // Move the text layer relative to its parent each animation tick.
    BOOL showAnimation = !_firstAnimation;
    _firstAnimation = NO;
    [self positionTextLayerRandomlyAnimated:showAnimation];
    
        // Check if we need to change the text yet.
    _ticksToChangeQuote--;
    if (_ticksToChangeQuote == 0 && _textLayer) {
        _textLayer.string = self.randomAttributedQuoteString;
        _ticksToChangeQuote = TICKS_BEFORE_CHANGING_QUOTE;
    }
    return;
}

- (BOOL)hasConfigureSheet {
    return YES;
}

- (NSWindow*)configureSheet {
    NSWindow *prefsWindow = nil;

    if (!_prefsController) {
        _prefsController = [[PreferencesWindowController alloc] initWithUserPreferences:_userPreferences];
    }
    NSAssert(_prefsController, @"PreferencesPanel failed to load.");
    prefsWindow = _prefsController.window;
    NSAssert(prefsWindow, @"PreferencesPanel controller %@ failed to create window.", _prefsController);
    return prefsWindow;
}

+ (BOOL)performGammaFade {
    return YES;
}


#pragma mark Private methods.

- (void)seedRandomNumberGenerator {
    NSTimeInterval timeInterval = [NSDate date].timeIntervalSinceReferenceDate;
    unsigned int seedValue = timeInterval * 1000;
    srandom(seedValue);
}

    /// Create a Quartz layer which shows an animated background.
- (CALayer *) createBackgroundLayerAbove: (CALayer*)parentLayer {
    
    NSBundle *saverBundle = [NSBundle bundleWithIdentifier:_userPreferences.bundleIdentifier];
    NSAssert(saverBundle, @"Bundle not found for identifier %@", _userPreferences.bundleIdentifier);
    NSString *compositionFile = [saverBundle pathForResource:@"Background" ofType:@"qtz"];
    NSAssert(compositionFile, @"Bundle %@ has no Background.qtz object.", saverBundle);
    CALayer *backgroundLayer = [QCCompositionLayer compositionLayerWithFile:compositionFile];
    NSAssert(backgroundLayer, @"QCCompositionLayer failed to load composition file %@", compositionFile);
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
    [self positionTextLayerRandomlyAnimated:NO];
    
    tl.string = [self randomAttributedQuoteString];
    tl.wrapped = YES;
    tl.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.0].CGColor; // transparent background.
    tl.anchorPoint = CGPointMake(0, 0);
    
        // Add a Core Image filter to merge the text with the background.
    CIFilter *overlayFilter = [CIFilter filterWithName:@"CIDivideBlendMode"];
    if (overlayFilter) {
        tl.compositingFilter = overlayFilter;
    } else {
        NSLog(@"Couldn't create overlay filter.");
    }
        // Add do-nothing actions for the properties we will animate so that the layer doesn't auto-animate the changes.
    tl.actions = @{@"position" : [[NullAction alloc] init], @"opacity" : [[NullAction alloc] init], @"translation" : [[NullAction alloc] init]};
    
    [parentLayer addSublayer:tl];
    
    return tl;
}

    /// Sets the position of the text layer randomly, ensuring it will always appear on-screen.
- (void)positionTextLayerRandomlyAnimated: (BOOL)animated {
    CGPoint newPosition = CGPointMake(SSRandomFloatBetween(0.0, self.bounds.size.width  * 0.25),
                                      SSRandomFloatBetween(0.0, self.bounds.size.height * 0.5 ));
    if (animated) {
        [self animateToPosition:newPosition];
    } else {
        _textLayer.position = newPosition;
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

    /// Trigger a text animation moving the text to NEWPOSITION.
- (void)animateToPosition: (CGPoint)newPosition {
    if (_textLayer) {
        
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithPoint:_textLayer.position];
        positionAnimation.toValue = [NSValue valueWithPoint:newPosition];
        
        CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        fadeAnimation.toValue = [NSNumber numberWithFloat:0.0];
        fadeAnimation.duration = 1.0;
        
        CAAnimationGroup *animationGroup = [[CAAnimationGroup alloc] init];
        animationGroup.animations = @[fadeAnimation, positionAnimation];
        animationGroup.duration = 2.0;
        
        [_textLayer addAnimation:animationGroup forKey:@"TextAdjustment"];
        
            // Create a timer to update the layer with the new values once the animation has completed.  I want a pause between the layer disappearing and reappearing in the new position, so I set the timer to fire after the layer completes.
        _restoreTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                         target:self
                                                       selector:@selector(movementComplete:)
                                                       userInfo:[NSValue valueWithPoint:newPosition]
                                                        repeats:NO];
        
            // Hide the layer. When the timer fires I'll undo this and make the layer visible again as well as updating the other properties.
        _textLayer.opacity = 0.0;
    }
}

    /// Triggered by the timer callback. This method moves the text layer into the position to match the end of the animation.
- (void)movementComplete:(NSTimer *)timer {
        // Final layer state when animation completes - reset it to the new position with no scaling, fully opaque.  The new position is taken from the userInfo property on the timer.
    NSValue *v = timer.userInfo;
    CGPoint newPosition = v.pointValue;
    if (_textLayer) {
        _textLayer.opacity = 1.0;
        _textLayer.position = newPosition;
    }
    NSAssert(timer == _restoreTimer, @"Timer %@ doesn't match the timer we set: %@", timer, _restoreTimer);
    if (_restoreTimer) {
        [_restoreTimer invalidate];
    }
    _restoreTimer = nil;
}

    /// Produce a random quote, loading the quotes file if necessary.
- (Quote *)randomQuote {
    if (!_allQuotes) {
        _allQuotes = [Quote loadQuotes:_userPreferences.documentFileURL];
    }
    if (_allQuotes.count > 0) {
        return _allQuotes[SSRandomIntBetween(0, (int)_allQuotes.count - 1)];
    }
        // Return a quote with explanatory text so the user can tell what went wrong.
    return [[Quote alloc] initWithText:@"There are no quotes to display" attribution:nil];
}


    /// Create and return a random attributed string containing the text and attributions in their appropriate colours.
- (NSAttributedString *)randomAttributedQuoteString {
    Quote *quote = self.randomQuote;
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
