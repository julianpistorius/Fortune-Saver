//
//  ExpandAndFade.m
//  Fortune
//
//  Created by Patrick Wallace on 05/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "ExpandAndFade.h"

@interface ExpandAndFade () {
    NSTimer *_restoreTimer;
}

@end

@implementation ExpandAndFade
@synthesize layer = _layer, replacementText = _replacementText;

- (void)animateToPosition:(CGPoint)newPosition {
    if (_layer) {
        
            // Fade the text out faster than the rest of the animation, so that the layer spends some time invisible before appearing at it's new position.
        CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        fadeAnimation.toValue = [NSNumber numberWithFloat:0.0];
        fadeAnimation.duration = 1.0;
        
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        CGPoint animationEndPosition = _layer.position;
        animationEndPosition.x -= _layer.bounds.size.width / 2;
        animationEndPosition.y -= _layer.bounds.size.height / 2;
        positionAnimation.fromValue = [NSValue valueWithPoint:_layer.position];
        positionAnimation.toValue = [NSValue valueWithPoint:animationEndPosition];
 
        CABasicAnimation *expandAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        expandAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        CATransform3D doubleSize = CATransform3DMakeScale(2, 2, 1);
        expandAnimation.toValue = [NSValue valueWithCATransform3D:doubleSize];
        
        CAAnimationGroup *animationGroup = [[CAAnimationGroup alloc] init];
        animationGroup.animations = @[fadeAnimation, positionAnimation, expandAnimation];
        animationGroup.duration = 2.0;
        
        animationGroup.delegate = self;
        
        [_layer addAnimation:animationGroup forKey:@"TextTransition"];
        
            // Create a timer to update the layer with the new values once the animation has completed.  I want a pause between the layer disappearing and reappearing in the new position, so I set the timer to fire after the animation completes.
        _restoreTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                         target:self
                                                       selector:@selector(movementComplete:)
                                                       userInfo:[NSValue valueWithPoint:newPosition]
                                                        repeats:NO];
        
            // Hide the layer. When the timer fires I'll undo this and make the layer visible again as well as updating the other properties.
        _layer.opacity = 0.0;
    }
}

- (BOOL)inProgress {
    return _restoreTimer != nil;
}


    /// Triggered by the timer callback. This method moves the text layer into the position to match the end of the animation.
- (void)movementComplete: (NSTimer *)sender {
    
        // Final layer state when animation completes - reset it to the new position with no scaling, fully opaque.  The new position is taken from the userInfo property on the timer.
    CGPoint newPosition = ((NSValue *)sender.userInfo).pointValue;
    if (_layer) {
            // Restore the layer's opacity once it is in the new position.
        _layer.position = newPosition;
        _layer.opacity = 1.0;
    }
    if (sender != _restoreTimer) { NSLog(@"Timer %@ doesn't match the timer we set: %@", sender, _restoreTimer); }
    if (_restoreTimer) {
        [_restoreTimer invalidate];
    }
    _restoreTimer = nil;
}

    /// Called when the animation ends and the layer is invisible. Change the text at this point if we have been given any replacement text.
- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)animationFinished {
    if (animationFinished && _layer && _replacementText) {
        _layer.string = _replacementText;
    }
    _replacementText = nil;
}

@end
