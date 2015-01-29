//
//  M13ContextMenu.m
//  M13ContextMenu
//
/*Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "M13ContextMenu.h"

#define M13ContextMenuShowAnimaitonIdentifier @"M13ContextMenuShowAnimation"
#define M13ContextMenuHideAnimationIdentifier @"M13ContextMenuHideAnimation"

#define M13ContextMenuItemPropertiesLayerKey @"layer"
#define M13ContextMenuItemPropertiesAngleKey @"angle"
#define M13ContextMenuItemPropertiesPositionKey @"position"

CGFloat const M13AnimationDuration = 0.2;
CGFloat const M13AnimationDelay = 0.04;

@interface M13ContextMenu () <UIGestureRecognizerDelegate>
{
    CADisplayLink *displayLink;
}
/**
 Wether or not the menu is showing.
 */
@property (nonatomic, assign) BOOL isActivated;
/**
 The initial point to display the menu.
 */
@property (nonatomic, assign) CGPoint originLocation;
/**
 The current location of the gesture.
 */
@property (nonatomic, assign) CGPoint currentLocation;
/**
 The array containing all the information about the menu items.
 */
@property (nonatomic, retain) NSMutableArray *items;
/**
 The angle (in radians) that the menu items are displaied over.
 */
@property (nonatomic, assign) CGFloat menuDisplayAngle;
/**
 The radius from the menu origination point that the items are displaied at.
 */
@property (nonatomic, assign) CGFloat radius;
/**
 The index of the currently selected item.
 */
@property (nonatomic, assign) NSInteger currentItemIndex;
/**
 The angle (in radians) between the menu items.
 */
@property (nonatomic, assign) CGFloat angleBetweenItems;

@end


@implementation M13ContextMenu

#pragma mark - Initalization

- (id)initWithMenuItems:(NSArray *)menuItems
{
    self = [super initWithFrame:[UIScreen mainScreen].applicationFrame];
    if (self) {
        //Basic setup
        self.userInteractionEnabled = YES;
        
        //Load the menu items
        _items = [NSMutableArray array];
        for (M13ContextMenuItem *item in menuItems) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setObject:item forKey:M13ContextMenuItemPropertiesLayerKey];
            [_items addObject:dictionary];
            item.opacity = 0.0;
            [self.layer addSublayer:item];
        }
        
        //Initial state
        self.backgroundColor = [UIColor clearColor];
        _menuDisplayAngle = M_PI_2;
        _radius = 110.0;
        _originationCircleStrokeColor = [UIColor colorWithRed:0.02 green:0.47 blue:1.0 alpha:0.5];
        _originationCircleStrokeWidth = 4.0;
        _originationCircleRadius = 25.0;
    }
    return self;
}

- (void)dealloc
{
    [displayLink invalidate];
}

#pragma mark - Touch Tracking

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint menuPoint = CGPointZero;
    
    //Need a way to determine the point to use based on the gesture recognizer type.
    
    //Get the point at whcih to display and convert it to window coordinates
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:touch.view];
    touchPoint = [touch.view convertPoint:touchPoint toView:nil];
    //Get the necessary layer at the touch point
    CALayer *layer = [[self.layer.presentationLayer hitTest:touchPoint] modelLayer];
    
    if (layer != nil) {
        //Reset the selection
        NSInteger index = [self indexOfClosestItemToLayer:layer atPoint:touchPoint];
        _currentItemIndex = index;
        [self resetSelection];
        
        menuPoint = layer.position;
    }
    
    [self dismissWithSelectedIndexForMenuAtPoint:menuPoint];
    
}

- (NSInteger)indexOfClosestItemToLayer:(CALayer *)layer atPoint:(CGPoint)point
{
    //Setup for the calculation
    CGFloat xDistance = CGFLOAT_MAX;
    CGFloat yDistance = CGFLOAT_MAX;
    CGFloat range = 40.0;
    
    for (int i = 0; i < _items.count; i++) {
        M13ContextMenuItem *item = _items[i][M13ContextMenuItemPropertiesLayerKey];
        //Calculate the distances
        xDistance = point.x - item.position.x;
        yDistance = point.y - item.position.y;
        //If we are in range, return. We want the first item that meets the requirements
        if (xDistance >= 0 && yDistance >= 0 && xDistance <= range && yDistance <= range) {
            return i;
        }
    }
    //No match, return not found
    return NSNotFound;
}

#pragma mark - Gesture

- (void)showMenuUponActivationOfGetsure:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        //Setup before showing the menu
        _currentItemIndex = NSNotFound;
        _originLocation = CGPointZero;
        _currentLocation = CGPointZero;
        self.backgroundColor = [UIColor clearColor];
        
        //Add the menu to the application window.
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        self.frame = [UIApplication sharedApplication].keyWindow.bounds;
        
        //Calculate the point at which to show the menu
        _originLocation = [gestureRecognizer locationInView:self];
        CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
        
        //Should we show the menu at the given point
        if (_delegate != nil && [_delegate respondsToSelector:@selector(shouldShowContextMenu:atPoint:)] && ![_delegate shouldShowContextMenu:self atPoint:point]) {
            //Cancel the showing
            [self removeFromSuperview];
            return;
        }
        
        //Set up the display link to sync the animations with the screen refresh rate.
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(highlightMenuItemForCurrentPoint)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        //Finish setting up
        self.frame = [UIScreen mainScreen].applicationFrame;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        _isActivated = YES;
        [self animateMenuInOrOut:YES];
        [self setNeedsDisplay];
        
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        //Update the current location of the gesture
        if (_isActivated) {
            _currentLocation = [gestureRecognizer locationInView:self];
        }
        
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        //Dismiss
        CGPoint point = [self convertPoint:_originLocation toView:gestureRecognizer.view];
        [self dismissWithSelectedIndexForMenuAtPoint:point];
    }
}

- (void)dismissWithSelectedIndexForMenuAtPoint:(CGPoint)point
{
    if (_delegate && [_delegate respondsToSelector:@selector(contextMenu:atPoint:didSelectItemAtIndex:)] && _currentItemIndex != NSNotFound) {
        [_delegate contextMenu:self atPoint:point didSelectItemAtIndex:_currentItemIndex];
        _currentItemIndex = NSNotFound;
    }
    
    [self hide];
}



#pragma mark - Animation

- (void)hide
{
    //Prep to hide
    if (_isActivated) {
        self.backgroundColor = [UIColor clearColor];
        [displayLink invalidate];
        self.isActivated = NO;
        [self animateMenuInOrOut:NO];
        [self setNeedsDisplay];
        [self removeFromSuperview];
    }
}

- (void)animateMenuInOrOut:(BOOL)animateIn
{
    if (animateIn) {
        [self layoutItems];
    }
    
    for (int i = 0; i < _items.count; i++) {
        NSDictionary *dictionary = _items[i];
        M13ContextMenuItem *item = dictionary[M13ContextMenuItemPropertiesLayerKey];
        
        //Prep for animation
        item.opacity = 0.0;
        
        CGPoint initialPosition = _originLocation;
        CGPoint finalPosition = ((NSValue *)dictionary[M13ContextMenuItemPropertiesPositionKey]).CGPointValue;
        
        double animationDelay = M13AnimationDelay * i;
        
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        //Swap the initial and final position based on wether we are animating in or out.
        positionAnimation.fromValue = [NSValue valueWithCGPoint:(animateIn ? initialPosition : finalPosition)];
        positionAnimation.toValue = [NSValue valueWithCGPoint:(animateIn ? finalPosition : initialPosition)];
        positionAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.5 :1.3 :.75 :1.0];
        positionAnimation.duration = M13AnimationDuration;
        positionAnimation.beginTime = [item convertTime:CACurrentMediaTime() fromLayer:nil] + animationDelay;
        [positionAnimation setValue:[NSNumber numberWithInt:i] forKey:(animateIn ? M13ContextMenuShowAnimaitonIdentifier : M13ContextMenuHideAnimationIdentifier)];
        positionAnimation.delegate = self;
        positionAnimation.removedOnCompletion = YES;
        
        //Add the animation to the layer
        [item addAnimation:positionAnimation forKey:@"MenuAnimation"];
    }
}

- (void)animationDidStart:(CAAnimation *)anim
{
    //If we are showing
    if ([anim valueForKey:M13ContextMenuShowAnimaitonIdentifier]) {
        //Get the layer that is being animated
        int index = [[anim valueForKey:M13ContextMenuShowAnimaitonIdentifier] intValue];
        NSDictionary *dictionary = _items[index];
        M13ContextMenuItem *item = dictionary[M13ContextMenuItemPropertiesLayerKey];
        
        //Change its opacity and position. We do this now, because we do not want the layer showing before the animation occurs
        item.opacity = 1.0;
        item.position = ((NSValue *)dictionary[M13ContextMenuItemPropertiesPositionKey]).CGPointValue;
        
    } else if ([anim valueForKey:M13ContextMenuHideAnimationIdentifier]) {
        int index = [[anim valueForKey:M13ContextMenuHideAnimationIdentifier] intValue];
        NSDictionary *dictionary = _items[index];
        M13ContextMenuItem *item = dictionary[M13ContextMenuItemPropertiesLayerKey];
        
        CGPoint position = _originLocation;
        //Change its opacity and position. Add these to the animation that is occuring.
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        
        item.position = position;
        [item setHighlighted:NO];
        item.opacity = 0.0;
        item.transform = CATransform3DIdentity;
        
        [CATransaction commit];
    }
}

- (void)highlightMenuItemForCurrentPoint
{
    if (_isActivated) {
        //Find the menu item that is the closest angle to the current point angle.
        CGFloat angle = [self angleBeweenStartinPoint:_originLocation endingPoint:_currentLocation];
        
        NSInteger index = NSNotFound;
        
        for (int i = 0; i < _items.count; i++) {
            NSDictionary *dictionary = _items[i];
            CGFloat itemAngle = ((NSNumber *)dictionary[M13ContextMenuItemPropertiesAngleKey]).floatValue;
            
            if (fabsf(itemAngle - angle) < _angleBetweenItems / 2.0) {
                //We found the closest menu item
                index = i;
                break;
            }
        }
        
        if (index != NSNotFound) {
            //Calculate the scale for the selected menu item.
            NSDictionary *dictionary = _items[index];
            M13ContextMenuItem *item = dictionary[M13ContextMenuItemPropertiesLayerKey];
            
            CGFloat distanceOfTouchFromCenter = sqrtf(powf(_currentLocation.x - _originLocation.x, 2.0) + powf(_currentLocation.y - _originLocation.y, 2.0));
            CGFloat maximumDistanceForScaling = _radius + (sqrtf(powf(item.baseSize.width, 2.0) + powf(item.baseSize.height, 2.0) / 2.0));
            CGFloat distanceOfTouchFromItem = fabsf(distanceOfTouchFromCenter - _radius) - ((_radius / 2.0) / (2.0 * sqrtf(2.0)));
            
            if (fabsf(distanceOfTouchFromCenter) < maximumDistanceForScaling && fabsf(distanceOfTouchFromCenter) > _originationCircleRadius) {
                //Select item and scale
                
                //Highlight the item
                item.highlighted = YES;
                
                //Set the scale
                CGFloat scale = 1 + (0.25 * (1 - (fabsf(distanceOfTouchFromItem) / maximumDistanceForScaling)));
                if (scale < 1.0) {
                    scale = 1.0;
                }
                
                //Create the transformations
                //Create the scale transformation
                CATransform3D scaleTransform = CATransform3DScale(CATransform3DIdentity, scale, scale, 1.0);
                
                //Create the translated transform
                CGFloat xTranslation = cosf(angle);
                CGFloat yTranslation = sinf(angle);
                
                CATransform3D fullTransform = CATransform3DTranslate(scaleTransform, 10 * scale * xTranslation, 10 * scale * yTranslation, 0.0);
                
                item.transform = fullTransform;
                
                //Reset the selection if we are selecting a new index
                _currentItemIndex = index;
                [self resetSelection];
                
            } else {
                //No item to select, reset selection
                _currentItemIndex = NSNotFound;
                [self resetSelection];
            }
        } else {
            //Not found, reset selection
            _currentItemIndex = NSNotFound;
            [self resetSelection];
        }
    }
}

- (void)resetSelection
{
    for (int i = 0; i < _items.count; i++) {
        //Reset each item but the current one.
        if (i != _currentItemIndex) {
            NSDictionary *dictionary = _items[i];
            M13ContextMenuItem *item = dictionary[M13ContextMenuItemPropertiesLayerKey];
            //Reset the layer
            item.position = ((NSValue *)dictionary[M13ContextMenuItemPropertiesPositionKey]).CGPointValue;
            item.transform = CATransform3DIdentity;
            item.highlighted = NO;
        }
    }
}

# pragma mark - Layout

- (void)reloadData
{
    //Reset the items dictionaries
    for (NSMutableDictionary *dictionary in _items) {
        [dictionary removeObjectForKey:M13ContextMenuItemPropertiesAngleKey];
        [dictionary removeObjectForKey:M13ContextMenuItemPropertiesPositionKey];
    }
}

- (void)layoutItems
{
    [self reloadData];
    
    //Get the size of the menu items.
    M13ContextMenuItem *tempItem = [_items lastObject][M13ContextMenuItemPropertiesLayerKey];
    CGSize itemSize = tempItem.baseSize;
    CGFloat itemRadius = sqrtf(powf(itemSize.width, 2.0) + powf(itemSize.height, 2.0)) / 2.0;
    _menuDisplayAngle = ((itemRadius * _items.count) / _radius) * 1.5;
    
    //If we are a full circle
    NSInteger divisor;
    if (_menuDisplayAngle >= M_PI * 2) {
        _menuDisplayAngle = M_PI * 2;
        divisor = _items.count;
    } else {
        divisor = _items.count - 1;
    }
    
    _angleBetweenItems = _menuDisplayAngle / (float)divisor;
    
    //Calculate the positions for each menu item
    for (int i = 0; i < _items.count; i++) {
        //Get the item properties
        NSMutableDictionary *dictionary = _items[i];
        
        //Calculate the angle for the menu item
        //Offset the angle to prevent the items from being off screen.
        float bearingRadians = [self angleBeweenStartinPoint:_originLocation endingPoint:self.center];
        CGFloat angle =  bearingRadians - _menuDisplayAngle / 2.0;
        //Calculate the angle of the item
        CGFloat itemAngle = angle + ((float)i * _angleBetweenItems);
        
        if (itemAngle > 2 *M_PI) {
            itemAngle -= 2*M_PI;
        }else if (itemAngle < 0){
            itemAngle += 2*M_PI;
        }
        
        [dictionary setObject:[NSNumber numberWithFloat:itemAngle] forKey:M13ContextMenuItemPropertiesAngleKey];
        
        //Calculate the position of the menu item
        CGPoint itemCenter = CGPointMake(_originLocation.x + cosf(itemAngle) * self.radius, _originLocation.y + sinf(itemAngle) * self.radius);
        [dictionary setObject:[NSValue valueWithCGPoint:itemCenter] forKey:M13ContextMenuItemPropertiesPositionKey];
        
        M13ContextMenuItem *item = dictionary[M13ContextMenuItemPropertiesLayerKey];
        //Reset the item transform
        item.transform = CATransform3DIdentity;
    }
    
}

- (CGFloat)angleBeweenStartinPoint:(CGPoint)startingPoint endingPoint:(CGPoint)endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y);
    float bearingRadians = atan2f(originPoint.y, originPoint.x);
    
    bearingRadians = (bearingRadians > 0.0 ? bearingRadians : (M_PI*2 + bearingRadians));
    
    return bearingRadians;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (_isActivated) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        //Setup
        CGContextSetLineWidth(context, _originationCircleStrokeWidth / 2);
        CGContextSetStrokeColorWithColor(context, _originationCircleStrokeColor.CGColor);
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        //Fill
        CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
        CGContextAddArc(context, _originLocation.x, _originLocation.y, _originationCircleRadius, 0.0, M_PI*2, YES);
        CGContextFillPath(context);
        //Stroke
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGContextAddArc(context, _originLocation.x, _originLocation.y, _originationCircleRadius - (_originationCircleStrokeWidth / 8), 0.0, M_PI*2, YES);
        CGContextStrokePath(context);
        //Finish
        CGContextRestoreGState(context);
    }
}

@end

@implementation M13ContextMenuItem

- (CGSize)baseSize
{
    return CGSizeMake(0, 0);
}


@end
