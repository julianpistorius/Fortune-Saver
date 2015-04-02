//
//  Quote.m
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "Quote.h"

@implementation Quote
@synthesize text = _text, attribution = _attribution;

-(instancetype) initWithText:(NSString*)text attribution:(NSString*)attribution {
    self = [super init];
    if(!self) { return nil; }
    _text = text ? text : @"";
    _attribution = attribution ? attribution : @"";
    return self;
}

+ (NSArray *)loadQuotes:(NSURL *)fileURL {
    NSError *error = nil;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:fileURL
                                                                   options:0
                                                                     error:&error];
    if (!document) { // Return the error as the only text, so it will appear on the screen.
        Quote *quote = [[Quote alloc] initWithText:error.description attribution:nil];
        return @[quote];
    }
        // Otherwise, copy the text, attribution values into an array.
    NSMutableArray *allQuotes = [NSMutableArray array];
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
        Quote *quote = [[Quote alloc] initWithText:text attribution:attribution];
        [allQuotes addObject:quote];
    }
    return allQuotes;
}
@end
