/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiCollectionviewCollectionSectionProxy.h"
#import "TiCollectionviewCollectionViewProxy.h"
#import "TiCollectionviewCollectionView.h"
#import "TiCollectionviewCollectionItem.h"

@interface TiCollectionviewCollectionSectionProxy ()
@property (nonatomic, readonly) id<TiCollectionviewCollectionViewDelegate> dispatcher;
@end

@implementation TiCollectionviewCollectionSectionProxy {
	NSMutableArray *_items;
}

@synthesize delegate = _delegate;
@synthesize sectionIndex = _sectionIndex;
@synthesize headerTitle = _headerTitle;
@synthesize footerTitle = _footerTitle;

-(NSString*)apiName
{
    return @"Ti.CollectionSection";
}

- (id)init
{
    self = [super init];
    if (self) {
		_items = [[NSMutableArray alloc] initWithCapacity:20];
    }
    return self;
}

- (id<TiCollectionviewCollectionViewDelegate>)dispatcher
{
	return _delegate != nil ? _delegate : self;
}

// These API's are used by the ListView directly. Not for public consumption
- (NSDictionary *)itemAtIndex:(NSUInteger)index
{
	if (index < [_items count]) {
		id item = [_items objectAtIndex:index];
		if ([item isKindOfClass:[NSDictionary class]]) {
			return item;
		}
	}
	return nil;
}

- (void) deleteItemAtIndex:(NSUInteger)index
{
    if ([_items count] <= index) {
        DLog(@"[WARN] ListSectionProxy: deleteItemAtIndex index is out of range");
    } else {
        [_items removeObjectAtIndex:index];
    }
}

- (void) addItem:(NSDictionary*)item atIndex:(NSUInteger)index
{
    if (index > [_items count]) {
        DLog(@"[WARN] ListSectionProxy: addItem:atIndex: index is out of range");
    } else {
        if (index == [_items count]) {
            [_items addObject:item];
        } else {
            [_items insertObject:item atIndex:index];
        }
    }
}



#pragma mark - Public API

- (NSArray *)items
{
	return [self.dispatcher dispatchBlockWithResult:^() {
		return [_items copy];
	}];
}

- (NSUInteger)itemCount
{
	return [[self.dispatcher dispatchBlockWithResult:^() {
		return [NSNumber numberWithUnsignedInteger:[_items count]];
	}] unsignedIntegerValue];
}

- (id)getItemAt:(id)args
{
	ENSURE_ARG_COUNT(args, 1);
	NSUInteger itemIndex = [TiUtils intValue:[args objectAtIndex:0]];
	return [self.dispatcher dispatchBlockWithResult:^() {
		return (itemIndex < [_items count]) ? [_items objectAtIndex:itemIndex] : nil;
	}];
}

- (void)setItems:(id)args
{
	[self setItems:args withObject:[NSDictionary dictionaryWithObject:NUMINT(UITableViewRowAnimationNone) forKey:@"animationStyle"]];
}

- (void)setItems:(id)args withObject:(id)properties
{
    ENSURE_TYPE_OR_NIL(args,NSArray);
    NSArray *items = args;
    NSUInteger oldCount = [_items count];
    NSUInteger newCount = [items count];
    if ( (oldCount != newCount)) {
        NSUInteger minCount = MIN(oldCount, newCount);
        NSUInteger maxCount = MAX(oldCount, newCount);
        NSUInteger diffCount = maxCount - minCount;
        
        //Dispath block for difference
        [self.dispatcher dispatchUpdateAction:^(UICollectionView *tableView) {
            [_items setArray:items];
            NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:diffCount];
            for (NSUInteger i = 0; i < diffCount; ++i) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:(minCount + i) inSection:_sectionIndex]];
            }
            if (newCount > oldCount) {
                [tableView insertItemsAtIndexPaths:indexPaths];
            } else {
                [tableView deleteItemsAtIndexPaths:indexPaths];
            }
        }];
        
        //Dispatch block for common items
        if (minCount > 0) {
            [self.dispatcher dispatchUpdateAction:^(UICollectionView *tableView) {
                NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:minCount];
                for (NSUInteger i = 0; i < minCount; ++i) {
                    [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:_sectionIndex]];
                }
                [tableView  reloadItemsAtIndexPaths:indexPaths];
            }];
        }
        
    } else {
        [self.dispatcher dispatchUpdateAction:^(UICollectionView *tableView) {
            [_items setArray:items];
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:_sectionIndex]];
        }];
    }
}

- (void)appendItems:(id)args
{
	ENSURE_ARG_COUNT(args, 1);
	NSArray *items = [args objectAtIndex:0];
	if ([items count] == 0) {
		return;
	}
	ENSURE_TYPE_OR_NIL(items,NSArray);
	[self.dispatcher dispatchUpdateAction:^(UICollectionView *tableView) {
		NSUInteger insertIndex = [_items count];
		[_items addObjectsFromArray:items];
		NSUInteger count = [items count];
		NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:count];
		for (NSUInteger i = 0; i < count; ++i) {
			[indexPaths addObject:[NSIndexPath indexPathForRow:insertIndex+i inSection:_sectionIndex]];
		}
		[tableView insertItemsAtIndexPaths:indexPaths];
	}];
}

- (void)insertItemsAt:(id)args
{
	ENSURE_ARG_COUNT(args, 2);
	NSUInteger insertIndex = [TiUtils intValue:[args objectAtIndex:0]];
	NSArray *items = [args objectAtIndex:1];
	if ([items count] == 0) {
		return;
	}
	ENSURE_TYPE_OR_NIL(items,NSArray);

	[self.dispatcher dispatchUpdateAction:^(UICollectionView *tableView) {
		if ([_items count] < insertIndex) {
			DLog(@"[WARN] ListView: Insert item index is out of range");
			return;
		}
		[_items replaceObjectsInRange:NSMakeRange(insertIndex, 0) withObjectsFromArray:items];
		NSUInteger count = [items count];
		NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:count];
		for (NSUInteger i = 0; i < count; ++i) {
			[indexPaths addObject:[NSIndexPath indexPathForRow:insertIndex+i inSection:_sectionIndex]];
		}
		[tableView insertItemsAtIndexPaths:indexPaths];
	}];
}

- (void)replaceItemsAt:(id)args
{
	ENSURE_ARG_COUNT(args, 3);
	NSUInteger insertIndex = [TiUtils intValue:[args objectAtIndex:0]];
	NSUInteger replaceCount = [TiUtils intValue:[args objectAtIndex:1]];
	NSArray *items = [args objectAtIndex:2];
	ENSURE_TYPE_OR_NIL(items,NSArray);

	[self.dispatcher dispatchUpdateAction:^(UICollectionView *tableView) {
		if ([_items count] < insertIndex) {
			DLog(@"[WARN] ListView: Replace item index is out of range");
			return;
		}
		NSUInteger actualReplaceCount = MIN(replaceCount, [_items count]-insertIndex);
		[_items replaceObjectsInRange:NSMakeRange(insertIndex, actualReplaceCount) withObjectsFromArray:items];
		NSUInteger count = [items count];
		NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:MAX(count, actualReplaceCount)];
		for (NSUInteger i = 0; i < actualReplaceCount; ++i) {
			[indexPaths addObject:[NSIndexPath indexPathForRow:insertIndex+i inSection:_sectionIndex]];
		}
		if (actualReplaceCount > 0) {
			[tableView deleteItemsAtIndexPaths:indexPaths];
		}
		[indexPaths removeAllObjects];
		for (NSUInteger i = 0; i < count; ++i) {
			[indexPaths addObject:[NSIndexPath indexPathForRow:insertIndex+i inSection:_sectionIndex]];
		}
		if (count > 0) {
			[tableView insertItemsAtIndexPaths:indexPaths];
		}
	}];
}

- (void)deleteItemsAt:(id)args
{
	ENSURE_ARG_COUNT(args, 2);
	NSUInteger deleteIndex = [TiUtils intValue:[args objectAtIndex:0]];
	NSUInteger deleteCount = [TiUtils intValue:[args objectAtIndex:1]];
	if (deleteCount == 0) {
		return;
	}
	
	[self.dispatcher dispatchUpdateAction:^(UICollectionView *tableView) {
		if ([_items count] <= deleteIndex) {
			DLog(@"[WARN] ListView: Delete item index is out of range");
			return;
		}
		NSUInteger actualDeleteCount = MIN(deleteCount, [_items count]-deleteIndex);
		if (actualDeleteCount == 0) {
			return;
		}
		[_items removeObjectsInRange:NSMakeRange(deleteIndex, actualDeleteCount)];
		NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:actualDeleteCount];
		for (NSUInteger i = 0; i < actualDeleteCount; ++i) {
			[indexPaths addObject:[NSIndexPath indexPathForRow:deleteIndex+i inSection:_sectionIndex]];
		}
		[tableView deleteItemsAtIndexPaths:indexPaths];
	}];
}

- (void)updateItemAt:(id)args
{
	ENSURE_ARG_COUNT(args, 2);
	NSUInteger itemIndex = [TiUtils intValue:[args objectAtIndex:0]];
	NSDictionary *item = [args objectAtIndex:1];
	ENSURE_TYPE_OR_NIL(item,NSDictionary);
	
	[self.dispatcher dispatchUpdateAction:^(UICollectionView *tableView) {
		if ([_items count] <= itemIndex) {
			DLog(@"[WARN] ListView: Update item index is out of range");
			return;
		}

        if (item != nil) {
            [_items replaceObjectAtIndex:itemIndex withObject:item];
        }

        NSArray *indexPaths = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:itemIndex inSection:_sectionIndex], nil];
		BOOL forceReload = NO;
		if (!forceReload) {
			TiCollectionviewCollectionItem *cell = (TiCollectionviewCollectionItem *)[tableView cellForItemAtIndexPath:[indexPaths objectAtIndex:0]];
			if ((cell != nil) && ([cell canApplyDataItem:item])) {
				cell.dataItem = item;
			} else {
				forceReload = YES;
			}
		}
		if (forceReload) {
			[tableView reloadItemsAtIndexPaths:indexPaths];
		}
	}];
}

#pragma mark - TiUIListViewDelegate

- (void)dispatchUpdateAction:(void (^)(UICollectionView *))block
{
	block(nil);
}

- (id)dispatchBlockWithResult:(id (^)(void))block
{
	return block();
}

@end
