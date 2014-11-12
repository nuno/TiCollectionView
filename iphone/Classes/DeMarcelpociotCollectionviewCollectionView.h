/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIView.h"
#import "DeMarcelpociotCollectionviewCollectionViewProxy.h"

@interface DeMarcelpociotCollectionviewCollectionView : TiUIView <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, UISearchDisplayDelegate, TiScrolling, TiProxyObserver >

#pragma mark - Private APIs

@property (nonatomic, readonly) UICollectionView *collectionView;
@property (nonatomic, readonly) BOOL isSearchActive;

- (void)setDictTemplates_:(id)args;
- (void)setContentInsets_:(id)value withObject:(id)props;
- (void)updateIndicesForVisibleRows;

@end