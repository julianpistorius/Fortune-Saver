//
//  MoveAndFade.m
//  Fortune
//
//  Created by Patrick Wallace on 05/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "MoveAndFade.h"
@import QuartzCore;

@interface MoveAndFade () {
    BOOL _inProgress;
}

@end

@implementation MoveAndFade
@synthesize layer = _layer, replacementText = _replacementText, inProgress = _inProgress;

- (instancetype)init
{
    self = [super init];
    if (!self) { return nil; }
    _inProgress = NO;
    return self;
}


- (void)animateToPosition:(CGPoint)newPosition {
    if (_layer) {
        
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithPoint:_layer.position];
        positionAnimation.toValue = [NSValue valueWithPoint:newPosition];
        positionAnimation.duration = 2.0;

        positionAnimation.delegate = self;
        
        [_layer addAnimation:positionAnimation forKey:@"TextTransition"];
        
            // Update the layer so it doesn't snap back once the animation ends.
        _layer.position = newPosition;
    }
}


#pragma mark CAAnimation delegate

- (void)animationDidStart:(CAAnimation *)anim {
    _inProgress = YES;
}

    /// Called when the animation completes. At this point, the layer will be invisible and we will be able to change the text before the timer triggers and the layer reappears.
- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)animationFinished {
    _inProgress = NO;
    if (animationFinished && _replacementText) {
        if (_layer) {
            _layer.string = _replacementText;
        }
        _replacementText = nil;
    }
}

@end
