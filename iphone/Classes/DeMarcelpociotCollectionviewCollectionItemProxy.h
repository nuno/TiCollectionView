/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiViewProxy.h"

@class DeMarcelpociotCollectionviewCollectionItem;
@class DeMarcelpociotCollectionviewCollectionViewProxy;

@interface DeMarcelpociotCollectionviewCollectionItemProxy : TiViewProxy <TiViewEventOverrideDelegate, TiProxyDelegate>

@property (nonatomic, readwrite, assign) DeMarcelpociotCollectionviewCollectionItem *listItem;
@property (nonatomic, readwrite, retain) NSIndexPath *indexPath;

- (id)initWithListViewProxy:(DeMarcelpociotCollectionviewCollectionViewProxy *)listViewProxy inContext:(id<TiEvaluator>)context;
-(void)deregisterProxy:(id<TiEvaluator>)context;
@end
