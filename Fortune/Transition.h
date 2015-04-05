//
//  Animation.h
//  Fortune
//
//  Created by Patrick Wallace on 05/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import Cocoa;
@import QuartzCore;

@protocol Transition <NSObject>

    /// The layer to animate. If nil, no animation will occur.
@property (nonatomic, weak) CATextLayer *layer;

    /// Returns true if the transition is currently running. Do not start another transition if this one is still running.
@property (nonatomic, readonly) BOOL inProgress;

    /// If this is non-nil when the animation completes, change the text while the layer is invisible and reset the pointer to nil again.
@property (nonatomic) NSAttributedString *replacementText;

    /// Animate LAYER changing from its current position to NEWPOSITION.
- (void)animateToPosition: (CGPoint)newPosition;

@end

