//
//  Extensions.h
//  Fortune
//
//  Created by Patrick Wallace on 25/02/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Cocoa;

    /// Extensions to the NSUserDefaults object.
@interface NSUserDefaults (ColourSupport)

    // Extensions for saving or loading specific objects.

    /// Return an NSColor object to the given key
- (NSColor*) colourForKey:(NSString *)key;

    /// Save an NSColor object for the given key.
- (void) setColour:(NSColor *)color forKey:(NSString *) key;

    /// Return an NSFont object for the given key.
- (NSFont *) fontForKey:(NSString *)key;

    /// Save an NSFont object for the given key.
- (void) setFont:(NSFont *)color forKey:(NSString *) key;

    // Extension for registering my defaults
- (void) registerMyDefaults;

@end

