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

static const NSUInteger TICK_INTERVAL = 30.0;  // One 'tick' per 30 seconds.
static const NSUInteger TICKS_BEFORE_CHANGING_QUOTE = 2 * 10; // Each tick is 30 seconds, so this is 10 minutes.

@interface PWQuote : NSObject
@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSString *attribution;
-(instancetype) initWithText:(NSString*)text attribution:(NSString*)attribution;
@end


@implementation PWQuote
@synthesize text = _text, attribution = _attribution;
-(instancetype) initWithText:(NSString*)text attribution:(NSString*)attribution {
    self = [super init];
    if(!self) { return nil; }
    _text = text ? text : @"";
    _attribution = attribution ? attribution : @"";
    return self;
}
@end

#pragma mark -

@interface FortuneView () {
    CALayer *_backgroundLayer;
    CATextLayer *_textLayer;
    NSMutableArray *_allQuotes;
    NSFont *_textFont;
    NSFont *_attributionFont;
    NSUInteger _ticksToChangeQuote;
}

#pragma mark Properties which will eventually be pulled from the preferences.
@property (nonatomic, readonly) NSColor *textColour, *attributionColour;
@property (nonatomic, readonly) NSURL *documentFileURL;
@property (nonatomic, readonly) NSString *fontName;
@property (nonatomic, readonly) CGFloat fontSize;

#pragma mark Private properties for readability.
@property (nonatomic, readonly) PWQuote *randomQuote;
@property (nonatomic, readonly) NSAttributedString *randomAttributedQuoteString;
@property (nonatomic, readonly) NSString *bundleIdentifier;
@property (nonatomic, readonly) NSArray *allQuotes;  // Of type Quote
@end

#pragma mark -

static const CGFloat PREVIEW_FONT_SIZE = 12;

@implementation FortuneView
@synthesize documentFileURL = _documentFileURL;

#pragma mark ScreensaverView method overrides.

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:TICK_INTERVAL]; // Note the Quartz composer uses it's own animation clock and ignores this value.
        self.wantsLayer = YES;
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
        self.layerUsesCoreImageFilters = YES;
        
            // Create the font we'll use for text depending if we're drawing in the preview window or the screen.
        CGFloat fontRealSize = isPreview ? PREVIEW_FONT_SIZE : self.fontSize; // Use a small font for the preview window, or a large one for the main window.
        _textFont = [NSFont fontWithName:self.fontName size:fontRealSize];
        if (!_textFont) { // Default font in case the specified one is not found.
            NSLog(@"Font %@ size %d not found, using system default", self.fontName, (int)fontRealSize);
            _textFont = [NSFont systemFontOfSize:fontRealSize];
        }
            // Ditto for attributions
        if (isPreview) {
            _attributionFont = [_textFont copy];
        } else {
            CGFloat attributionFontSize = fontRealSize - 10.0;
            _attributionFont = [NSFont fontWithName:self.fontName size:attributionFontSize];
        }
        _ticksToChangeQuote = TICKS_BEFORE_CHANGING_QUOTE;
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

#pragma mark Preference attributes

- (NSString *)fontName { return @"Futura"; }
- (CGFloat) fontSize { return 40; }
- (NSColor *)textColour { return /*[NSColor colorWithWhite:1.0 alpha:0.5];*/ [[NSColor blackColor] colorWithAlphaComponent:0.5]; }
- (NSColor *)attributionColour { return /*[[NSColor redColor] colorWithAlphaComponent:0.75]*/ [NSColor magentaColor]; }
- (NSURL *)documentFileURL {
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectoryURL = urls[0];
    return [NSURL URLWithString:@"net-sigs.xml" relativeToURL:documentsDirectoryURL];
}

#pragma mark Private methods.

- (PWQuote *)randomQuote {
    NSArray *allQuotes = self.allQuotes;
    if (allQuotes.count > 0) {
        return allQuotes[SSRandomIntBetween(0, (int)allQuotes.count - 1)];
    }
        // Return a quote with explanatory text so the user can tell what went wrong.
    return [[PWQuote alloc] initWithText:@"There are no quotes to display" attribution:nil];
}

- (NSString *)bundleIdentifier {
    return @"Patrick-Wallace.Fortune";
}


    /// Create a Quartz layer which shows an animated background.
- (CALayer *) createBackgroundLayerAbove: (CALayer*)parentLayer {
    
    NSBundle *saverBundle = [NSBundle bundleWithIdentifier:self.bundleIdentifier];
    NSAssert(saverBundle, @"Bundle not found for identifier %@", self.bundleIdentifier);
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

    /// Create and return a random attributed string containing the text and attributions in their appropriate colours.
- (NSAttributedString *)randomAttributedQuoteString {
    PWQuote *quote = self.randomQuote;
    NSString *fullTextString = [NSString stringWithFormat:@"%@\n", quote.text];
    NSDictionary *textStringAttributes = @{ NSFontAttributeName : _textFont,
                                            NSForegroundColorAttributeName : self.textColour };
    
    NSMutableAttributedString *quoteString = [[NSMutableAttributedString alloc] initWithString:fullTextString attributes:textStringAttributes];
    
    if (quote.attribution.length > 0) {
        NSDictionary *attributionStringAttributes = @{NSFontAttributeName : _attributionFont,
                                                      NSForegroundColorAttributeName : self.attributionColour };
        NSString *fullAttributionString = [NSString stringWithFormat:@"\t—%@", quote.attribution];
        NSAttributedString *attributionString = [[NSAttributedString alloc] initWithString:fullAttributionString attributes:attributionStringAttributes];
        [quoteString appendAttributedString:attributionString];
    }
    return quoteString;
}

    /// Load the quotes from the user's XML document file and return an array of PWQuote objects.
- (NSArray *)allQuotes {
    if (_allQuotes) { return _allQuotes; }
    NSError *error = nil;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:self.documentFileURL
                                                                   options:0
                                                                     error:&error];
    if (!document) { // Return the error as the only text, so it will appear on the screen.
        PWQuote *quote = [[PWQuote alloc] initWithText:error.description attribution:nil];
        return @[quote];
    }
        // Otherwise, copy the text, attribution values into an array.
    _allQuotes = [NSMutableArray array];
    NSXMLElement *root = document.rootElement;
    NSAssert([root.name isEqualToString:@"Quotes"], @"XML Root node %@ has name %@, should be 'Quotes'", root, root.name);
    NSArray *allQuoteElements = [root elementsForName:@"Quote"];
    NSAssert(allQuoteElements, @"XML root %@ has no elements named 'Quote'", root);
    for (NSXMLElement *quoteElement in allQuoteElements) {
        NSString *text = nil, *attribution = nil;
        for (NSXMLNode *node in quoteElement.children) {
            NSAssert([node.name isEqualToString:@"Text"] || [node.name isEqualToString:@"Attribution"], @"Node %@ is unrecognised.", node);
            if      ([node.name isEqualToString:@"Text"]       ) { text        = node.stringValue; }
            else if ([node.name isEqualToString:@"Attribution"]) { attribution = node.stringValue; }
        }
        PWQuote *quote = [[PWQuote alloc] initWithText:text attribution:attribution];
        [_allQuotes addObject:quote];
    }
    return _allQuotes;
}

@end
