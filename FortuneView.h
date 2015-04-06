//
//  PWTestView.h
//  PWTest
//
//  Created by Patrick Wallace on 27/03/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import "BackgroundManager.h"
#import "FilterManager.h"

@interface FortuneView : ScreenSaverView <BackgroundManagerObserver, FilterManagerObserver>

@end
