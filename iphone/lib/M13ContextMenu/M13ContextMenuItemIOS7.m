//
//  M13ContextMenuItemIOS7.m
//  M13ContextMenu
//
/*Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "M13ContextMenuItemIOS7.h"

@interface M13ContextMenuItemIOS7 ()

@property (nonatomic, retain) UIImage *selectedIcon;
@property (nonatomic, retain) UIImage *unselectedIcon;

@end

@implementation M13ContextMenuItemIOS7

- (id)initWithUnselectedIcon:(UIImage *)unselected selectedIcon:(UIImage *)selected
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, self.baseSize.width, self.baseSize.height);
        self.bounds = self.frame;
        self.backgroundColor = [UIColor whiteColor].CGColor;
        self.cornerRadius = self.baseSize.width / 2.0;
        self.masksToBounds = YES;
        self.contentsScale = [UIScreen mainScreen].scale;
        _selectedIcon = selected;
        _unselectedIcon = unselected;
        _tintColor = [UIColor colorWithRed:0.02 green:0.47 blue:1.0 alpha:1.0];
        _highlightedTintColor = [UIColor whiteColor];
        [self setHighlighted:NO];
    }
    return self;
}

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self) {
        M13ContextMenuItemIOS7 *item = layer;
        _selectedIcon = item.selectedIcon;
        _unselectedIcon = item.unselectedIcon;
        _tintColor = item.tintColor;
        _highlightedTintColor = item.highlightedTintColor;
        [self setHighlighted:item.highlighted];
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx
{
    [super drawInContext:ctx];
    
    UIImage *image = self.highlighted ? _selectedIcon : _unselectedIcon;
    UIColor *color = self.highlighted ? _highlightedTintColor : _tintColor;
    image = [self tintedImage:image WithColor:color];
    image = [self rotatedImage:image withOrientation:[UIApplication sharedApplication].statusBarOrientation];
    
    CGRect rect = CGRectIntegral(CGRectInset(self.bounds, self.bounds.size.width * 0.2, self.bounds.size.height * 0.2));
    
    CGContextDrawImage(ctx, rect, image.CGImage);
}


#pragma mark - Overrides

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (self.highlighted) {
        self.backgroundColor = _tintColor.CGColor;
    } else {
        self.backgroundColor = [UIColor whiteColor].CGColor;
    }
    [self setNeedsDisplay];
}

- (UIImage *)tintedImage:(UIImage *)image WithColor:(UIColor *)color
{
    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // draw alpha-mask
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, image.CGImage);
    
    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(context, rect);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}

- (UIImage *)rotatedImage:(UIImage *)image withOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation != UIInterfaceOrientationPortrait) {
        CGFloat angle;
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            angle = M_PI_2;
        } else if (orientation == UIInterfaceOrientationLandscapeRight) {
            angle = - M_PI_2;
        } else {
            angle = M_PI;
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0, image.size.width, image.size.height)];
        CGAffineTransform t = CGAffineTransformMakeRotation(angle);
        rotatedViewBox.transform = t;
        CGSize rotatedSize = rotatedViewBox.frame.size;
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize);
        CGContextRef bitmap = UIGraphicsGetCurrentContext();
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, angle);
        
        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, 1.0, -1.0);
        CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;

    }
    //No need to rotate
    return image;
}

- (CGSize)baseSize
{
    return CGSizeMake(50, 50);
}

@end
