/**
 * TiCollectionView
 *
 * Created by Your Name
 * Copyright (c) 2014 Your Company. All rights reserved.
 */

#import "DeMarcelpociotCollectionviewModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "DeMarcelpociotCollectionviewCollectionView.h"
#import "CHTCollectionViewWaterfallLayout.h"

@implementation DeMarcelpociotCollectionviewModule


#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"eef8bad5-aef3-49fb-bb8d-7cb781e9e7f5";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"de.marcelpociot.collectionview";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably

	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

MAKE_SYSTEM_PROP(LAYOUT_GRID, kLayoutTypeGrid);
MAKE_SYSTEM_PROP(LAYOUT_WATERFALL, kLayoutTypeWaterfall );

MAKE_SYSTEM_PROP(DIRECTION_LEFT_TO_RIGHT,CHTCollectionViewWaterfallLayoutItemRenderDirectionLeftToRight);
MAKE_SYSTEM_PROP(DIRECTION_RIGHT_TO_LEFT, CHTCollectionViewWaterfallLayoutItemRenderDirectionRightToLeft);
MAKE_SYSTEM_PROP(DIRECTION_SHORTEST_FIRST, CHTCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst);

MAKE_SYSTEM_PROP(SCROLL_HORIZONTAL, kScrollHorizontal);
MAKE_SYSTEM_PROP(SCROLL_VERTICAL, kScrollVertical);


@end
