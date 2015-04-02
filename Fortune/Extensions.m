//
//  Extensions.m
//  Fortune
//
//  Created by Patrick Wallace on 25/02/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "Extensions.h"
#import "UserPreferences.h"

static NSFont *defaultFont() {
    return [NSFont systemFontOfSize:[NSFont systemFontSize]];
}

    /// Extensions to NSUserDefaults (and ScreenSaverDefaults)
@implementation NSUserDefaults (ColourSupport)

- (NSColor*) colourForKey:(NSString *)key {
    NSData *data = [self objectForKey:key];
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return color;
}

- (void) setColour:(NSColor *)colour forKey:(NSString *)key {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:colour];
    [self setObject:data forKey:key];
}

-(NSFont *) fontForKey:(NSString *)key {
    NSString *fontDescription = [self stringForKey:key];
    NSArray *array = [fontDescription componentsSeparatedByString:@"::"];
    NSString *name = nil;
    NSUInteger size = [NSFont systemFontSize];
    name = array[0];
    if (array.count >= 2) {
        NSString *sizeStr = array[1];
        size = sizeStr.integerValue;
    }
    
    NSFont *font = [NSFont fontWithName:name size:size];
    return font;
}

-(void) setFont:(NSFont *)font forKey:(NSString *)key {
    NSString *name = font.fontName;
    NSUInteger size = font.pointSize;
    NSString *fontDescription = [NSString stringWithFormat:@"%@::%lu", name, size];
    [self setObject:fontDescription forKey:key];
    
}

- (void)registerMyDefaults {
    [self registerDefaults:@{kTextFont          : defaultFont(),
                             kAttributionFont   : defaultFont(),
                             kTextColour        : [NSKeyedArchiver archivedDataWithRootObject:[NSColor whiteColor]],
                             kAttributionColour : [NSKeyedArchiver archivedDataWithRootObject:[NSColor redColor  ]]
                             }];
    [self synchronize];
    
        // Check it worked.
    NSAssert( [self colourForKey:kAttributionColour] != nil, @"User defaults - Stored attribution colour came back as nil.");
}


@end


