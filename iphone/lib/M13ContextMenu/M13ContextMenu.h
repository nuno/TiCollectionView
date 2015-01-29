//
//  M13ContextMenu.h
//  M13ContextMenu
//
/*Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <UIKit/UIKit.h>

@class M13ContextMenu;
@class M13ContextMenuItem;

@protocol  M13ContextMenuDelegate <NSObject>

/**
 Determines wether or not the context menu should show.
 
 @param contextMenu The context menu that wants to display
 @param point       The point at which the context menu wants to display in the coordinate space of the view containing the gesture.
 
 @return Whether or not the context menu should show.
 */
- (BOOL)shouldShowContextMenu:(M13ContextMenu *)contextMenu atPoint:(CGPoint)point;
/**
 Lets the delegate know that the menu selected a given menu item.
 
 @param contextMenu The context menu that selected an item.
 @param point       The location of the menu.
 @param index       The index of the selected menu item.
 */
- (void)contextMenu:(M13ContextMenu *)contextMenu atPoint:(CGPoint)point didSelectItemAtIndex:(NSInteger)index;

@end

@interface M13ContextMenu : UIView

/**@name Initalization*/
/**
 Initalize the context menu with a set of menu items.

 @param menuItems An array of the menu items to populate the context menu with.
 
 @note The menu items will be expanded to 125% of their base size when selected. If the item contains an image, it should be 125% larger than the base size.

 @return A new context menu.
*/
- (id)initWithMenuItems:(NSArray *)menuItems;

/**@name Actions*/
/**
 The menu's delegate
 */
@property (nonatomic, retain) id<M13ContextMenuDelegate> delegate;
/**
 The selector to set the gesture recognizer's target to, to display the menu upon gesture activation.
 
 @param gestureRecognizer The gesture recognizer that activated to display the menu.
 */
- (void)showMenuUponActivationOfGetsure:(UIGestureRecognizer *)gestureRecognizer;

/**@name Appearance*/
/**
 The radius of the circle that marks the menu origination point.
 */
@property (nonatomic, assign) CGFloat originationCircleRadius;
/**
 The width of the stroke around the circle that marks the menu origination point.
 */
@property (nonatomic, assign) CGFloat originationCircleStrokeWidth;
/**
 The color of the stroke around the circle that marks the menu origination point.
 */
@property (nonatomic, retain) UIColor *originationCircleStrokeColor;

@end

@interface M13ContextMenuItem : CALayer
/**
 Wether or not item is highlighted. The item should draw diffrently in the two diffrent states.
 */
@property (nonatomic, assign) BOOL highlighted;
/**
 The base size of the item.
 
 @return The size of the item.
 */
- (CGSize)baseSize;

@end
