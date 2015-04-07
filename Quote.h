//
//  Quote.h
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Foundation;
#import "UserPreferences.h"
@class Quote;

@interface Quotations : NSObject <UserPreferencesObserver>

    /// Return the pointer to the single instance of this object.
+ (instancetype)sharedInstance;

    /// Call to refresh the quotes from the document file specified in the preferencs. Use when the preferences document has changed.
- (void)reload;

    /// Returns a cached list of quotes which is shared between the views.
@property (nonatomic, readonly) NSArray *allQuotes;

    /// Returns a random quote each time one is requested.
@property (nonatomic, readonly) Quote *randomQuote;
@end


@interface Quote : NSObject

@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSString *attribution;

@end
