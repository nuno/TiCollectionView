/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIView.h"
#import "TiCollectionviewCollectionViewProxy.h"
#import "CHTCollectionViewWaterfallLayout.h"
#import "TiSearchDisplayController.h"

typedef enum {
    kLayoutTypeGrid,
    kLayoutTypeWaterfall
} LayoutType;

typedef enum {
    kScrollHorizontal,
    kScrollVertical
} ScrollDirection;

@interface TiCollectionviewCollectionView : TiUIView <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, TiSearchDisplayDelegate, TiScrolling, TiProxyObserver, CHTCollectionViewDelegateWaterfallLayout>

#pragma mark - Private APIs

@property (nonatomic, readonly) UICollectionView *collectionView;
@property (nonatomic, readonly) BOOL isSearchActive;

- (void)setDictTemplates_:(id)args;
- (void)setContentInsets_:(id)value withObject:(id)props;
- (void)updateIndicesForVisibleRows;
- (void)updateSearchResults:(id)unused;

@end
