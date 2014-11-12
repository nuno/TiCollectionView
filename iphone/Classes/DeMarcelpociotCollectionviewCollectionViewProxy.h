/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiViewProxy.h"
#import "DeMarcelpociotCollectionviewCollectionSectionProxy.h"

@interface DeMarcelpociotCollectionviewCollectionViewProxy : TiViewProxy < DeMarcelpociotCollectionviewCollectionViewDelegate >

@property (nonatomic, readonly) NSArray *sections;
@property (nonatomic, readonly) NSNumber *sectionCount;

- (DeMarcelpociotCollectionviewCollectionSectionProxy *)sectionForIndex:(NSUInteger)index;
- (void) deleteSectionAtIndex:(NSUInteger)index;
- (void) setMarker:(id)args;
@end

@interface DeMarcelpociotCollectionviewCollectionViewProxy (internal)
-(void)willDisplayCell:(NSIndexPath*)indexPath;
@end
