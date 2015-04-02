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

static const NSUInteger TICK_INTERVAL = 30.0;  // One 'tick' per 30 seconds.
static const NSUInteger TICKS_BEFORE_CHANGING_QUOTE = 2 * 10; // Each tick is 30 seconds, so this is 10 minutes.


@interface FortuneView () {
    CALayer         *_backgroundLayer;
    CATextLayer     *_textLayer;
    NSArray         *_allQuotes;  // Of type Quote
    NSFont          *_textFont;
    NSFont          *_attributionFont;
    UserPreferences *_userPreferences;
    NSUInteger _ticksToChangeQuote;
}


#pragma mark Private properties for readability.
@property (nonatomic, readonly) Quote *randomQuote;
@property (nonatomic, readonly) NSAttributedString *randomAttributedQuoteString;
@end

#pragma mark -

static const CGFloat PREVIEW_FONT_SIZE = 12;

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
        
        _ticksToChangeQuote = TICKS_BEFORE_CHANGING_QUOTE;
        _userPreferences = [[UserPreferences alloc] init];
        
            // Create the font we'll use for text depending if we're drawing in the preview window or the screen.
        CGFloat fontRealSize = isPreview ? PREVIEW_FONT_SIZE : _userPreferences.fontSize; // Use a small font for the preview window, or a large one for the main window.
        _textFont = [NSFont fontWithName:_userPreferences.fontName size:fontRealSize];
        if (!_textFont) { // Default font in case the specified one is not found.
            NSLog(@"Font %@ size %d not found, using system default", _userPreferences.fontName, (int)fontRealSize);
            _textFont = [NSFont systemFontOfSize:fontRealSize];
        }
            // Ditto for attributions
        if (isPreview) {
            _attributionFont = [_textFont copy];
        } else {
            CGFloat attributionFontSize = fontRealSize - 10.0;
            _attributionFont = [NSFont fontWithName:_userPreferences.fontName size:attributionFontSize];
        }
    }
    return self;
}

- (void)startAnimation {
    [super startAnimation];

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
    [self positionTextLayerRandomly];
    
        // Animation - Fade out + expand, then Fade in + contract at new position.
    
        // Check if we need to change the text yet.
    _ticksToChangeQuote--;
    if (_ticksToChangeQuote == 0 && _textLayer) {
        _textLayer.string = self.randomAttributedQuoteString;
        _ticksToChangeQuote = TICKS_BEFORE_CHANGING_QUOTE;
    }
    return;
}

- (BOOL)hasConfigureSheet {
    return NO;
}

- (NSWindow*)configureSheet {
    return nil;
}

+ (BOOL)performGammaFade {
    return YES;
}


#pragma mark Private methods.

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
    [self positionTextLayerRandomly];
    
    tl.string = self.randomAttributedQuoteString;
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
- (void)positionTextLayerRandomly {
    _textLayer.position = CGPointMake(SSRandomFloatBetween(0.0, self.bounds.size.width  * 0.25),
                                      SSRandomFloatBetween(0.0, self.bounds.size.height * 0.5 ));
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
