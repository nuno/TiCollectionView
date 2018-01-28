/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiBase.h"
#import "TiProxy.h"

@protocol TiCollectionviewCollectionViewDelegate <NSObject>
@required

- (void)dispatchUpdateAction:(void(^)(UICollectionView *tableView))block;
- (id)dispatchBlockWithResult:(id(^)(void))block;

@end

@interface TiCollectionviewCollectionSectionProxy : TiProxy < TiCollectionviewCollectionViewDelegate >

@property (nonatomic, readwrite, assign) id<TiCollectionviewCollectionViewDelegate> delegate;
@property (nonatomic, readwrite, assign) NSUInteger sectionIndex;

// Private API. Used by ListView directly. Not for public comsumption
- (NSDictionary *)itemAtIndex:(NSUInteger)index;
- (void) deleteItemAtIndex:(NSUInteger)index;
- (void) addItem:(NSDictionary*)item atIndex:(NSUInteger)index;

// Public API
@property (nonatomic, readonly) NSUInteger itemCount;
@property (nonatomic, readonly) NSArray *items;
@property (nonatomic, readwrite, copy) NSString *headerTitle;
@property (nonatomic, readwrite, copy) NSString *footerTitle;

@end
