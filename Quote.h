//
//  Quote.h
//  Fortune
//
//  Created by Patrick Wallace on 02/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Foundation;

@interface Quote : NSObject

@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSString *attribution;


-(instancetype) initWithText:(NSString*)text attribution:(NSString*)attribution;

+(NSArray *)loadQuotes: (NSURL *)fileURL;

@end
