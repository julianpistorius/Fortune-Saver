//
//  UserPreferences.m
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "UserPreferences.h"

@implementation UserPreferences
@synthesize documentFileURL = _documentFileURL;

- (NSString *)fontName { return @"Futura"; }
- (CGFloat) fontSize { return 40; }
- (NSColor *)textColour { return /*[NSColor colorWithWhite:1.0 alpha:0.5];*/ [[NSColor blackColor] colorWithAlphaComponent:0.5]; }
- (NSColor *)attributionColour { return /*[[NSColor redColor] colorWithAlphaComponent:0.75]*/ [NSColor magentaColor]; }

-(instancetype)init {
    self = [super init];
    if (!self) { return nil; }
    
        // Find the document URL by default under the user's Documents directory.
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectoryURL = urls[0];
    _documentFileURL = [NSURL URLWithString:@"net-sigs.xml" relativeToURL:documentsDirectoryURL];
    return self;
}

- (NSString *)bundleIdentifier {
    return @"Patrick-Wallace.Fortune";
}


@end
