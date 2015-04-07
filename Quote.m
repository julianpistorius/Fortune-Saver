//
//  Quote.m
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import ScreenSaver;
#import "Quote.h"
@class Quotations;

static Quotations *instance = nil;

@interface Quotations () {
    NSArray *_allQuotes; // type Quote
    UserPreferences *_userPreferences;
    NSURL *_quotesFileURL;
}
- (NSArray *)loadQuotes:(NSURL *)fileURL;
@end

@interface Quote ()
- (instancetype)initWithText:(NSString *)text attribution:(NSString *)attribution NS_DESIGNATED_INITIALIZER;
@end

#pragma mark -

@implementation Quotations

+(instancetype)sharedInstance {
    if (!instance) {
        instance = [[Quotations alloc] init];
    }
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (!self) { return nil; }

    _userPreferences = [UserPreferences sharedPreferences];
    [_userPreferences addObserver:self];
    [self reload];

    return self;
}

- (void)dealloc
{
    [_userPreferences removeObserver:self];
}

- (void)reload {
    _quotesFileURL = _userPreferences.quotesFileURL;
    if (!_quotesFileURL) {
        _quotesFileURL = _userPreferences.fallbackQuotesFileURL;
    }
    _allQuotes = [self loadQuotes:_quotesFileURL];
}

- (Quote *)randomQuote {
    if (_allQuotes.count > 0) {
        NSUInteger randomValue = SSRandomIntBetween(0, (int)_allQuotes.count - 1);
        return _allQuotes[randomValue];
    }
        // Return a quote with explanatory text so the user can tell what went wrong.
    return [[Quote alloc] initWithText:@"There are no quotes to display" attribution:nil];
}

#pragma mark Observers

- (void)userPreferencesChanged:(UserPreferences *)userPreferences {
    if (![_quotesFileURL isEqual:userPreferences.quotesFileURL]) {
        [self reload];
    }
}

#pragma mark Private Methods

- (NSArray *)loadQuotes:(NSURL *)fileURL {
    NSError *error = nil;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:fileURL
                                                                   options:0
                                                                     error:&error];
    if (!document) { // Return the error as the only text, so it will appear on the screen.
        return [self quotesFromError:error];
    }
        // Otherwise, copy the text & attribution values into an array.
    NSMutableArray *allQuotes = [NSMutableArray array];
    NSXMLElement *root = document.rootElement;
    if (![root.name isEqualToString:@"Quotes"]) { NSLog(@"XML Root node %@ has name %@, should be 'Quotes'", root, root.name); }
    NSArray *allQuoteElements = [root elementsForName:@"Quote"];
    if (!allQuoteElements) { NSLog(@"XML root %@ has no elements named 'Quote'", root); }
    for (NSXMLElement *quoteElement in allQuoteElements) {
        NSString *text = nil, *attribution = nil;
        for (NSXMLNode *node in quoteElement.children) {
            if      ([node.name isEqualToString:@"Text"]       ) { text        = node.stringValue; }
            else if ([node.name isEqualToString:@"Attribution"]) { attribution = node.stringValue; }
            else                                                 { NSLog(@"Node %@ is unrecognised.", node); }
        }
        Quote *quote = [[Quote alloc] initWithText:text attribution:attribution];
        [allQuotes addObject:quote];
    }
    return allQuotes;
}

- (NSArray *)quotesFromError:(NSError *)error {
        // If the error has a userInfo then use that filename as the attribution, otherwise get it from the user defaults.
    NSString *attribs = error.userInfo[NSFilePathErrorKey];
    if (!attribs) {
        attribs = _userPreferences.quotesFileURL.description;
        if (!attribs) {
            attribs = _userPreferences.fallbackQuotesFileURL.description;
        }
    }
    
    NSString *description = error.localizedDescription ? error.localizedDescription : @"";
    NSString *failureReason = error.localizedFailureReason ? error.localizedFailureReason : @"";
    NSString *recoverySuggestion = error.localizedRecoverySuggestion ? error.localizedRecoverySuggestion : @"";
    NSString *text = [NSString stringWithFormat:@"Error loading quotes: %@ %@ %@", description, failureReason, recoverySuggestion];
    Quote *quote = [[Quote alloc] initWithText:text attribution:attribs];
    return @[quote];
}

@end


#pragma mark -

@implementation Quote
@synthesize text = _text, attribution = _attribution;

-(instancetype) initWithText:(NSString*)text attribution:(NSString*)attribution {
    self = [super init];
    if(!self) { return nil; }
    _text = text ? text : @"";
    _attribution = attribution ? attribution : @"";
    return self;
}

@end
