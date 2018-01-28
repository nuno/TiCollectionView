/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import <UIKit/UIKit.h>
#import "TiGradient.h"
#import "TiCollectionviewCollectionView.h"
#import "TiCollectionviewCollectionItemProxy.h"
#import "TiSelectedCellbackgroundView.h"

enum {
	TiUIListItemTemplateStyleCustom = -1
};

@interface TiCollectionviewCollectionItem : UICollectionViewCell
{
	TiGradientLayer * gradientLayer;
	TiGradient * backgroundGradient;
	TiGradient * selectedBackgroundGradient;
}

@property (nonatomic, readonly) NSInteger templateStyle;
@property (nonatomic, readonly) TiCollectionviewCollectionItemProxy *proxy;
@property (nonatomic, readwrite, retain) NSDictionary *dataItem;

- (void)initWithProxy:(TiCollectionviewCollectionItemProxy *)proxy;

- (BOOL)canApplyDataItem:(NSDictionary *)otherItem;
- (void)setPosition:(int)position isGrouped:(BOOL)grouped;
- (void)configureCellBackground;
@end
