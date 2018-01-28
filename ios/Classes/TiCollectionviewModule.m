/**
 * TiCollectionView
 *
 * Created by Your Name
 * Copyright (c) 2014 Your Company. All rights reserved.
 */

#import "TiCollectionviewModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiCollectionviewCollectionView.h"
#import "CHTCollectionViewWaterfallLayout.h"

@implementation TiCollectionviewModule


#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"eef8bad5-aef3-49fb-bb8d-7cb781e9e7f5";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"Ti.collectionview";
}

MAKE_SYSTEM_PROP(LAYOUT_GRID, kLayoutTypeGrid);
MAKE_SYSTEM_PROP(LAYOUT_WATERFALL, kLayoutTypeWaterfall );

MAKE_SYSTEM_PROP(DIRECTION_LEFT_TO_RIGHT,CHTCollectionViewWaterfallLayoutItemRenderDirectionLeftToRight);
MAKE_SYSTEM_PROP(DIRECTION_RIGHT_TO_LEFT, CHTCollectionViewWaterfallLayoutItemRenderDirectionRightToLeft);
MAKE_SYSTEM_PROP(DIRECTION_SHORTEST_FIRST, CHTCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst);

MAKE_SYSTEM_PROP(SCROLL_HORIZONTAL, kScrollHorizontal);
MAKE_SYSTEM_PROP(SCROLL_VERTICAL, kScrollVertical);


@end
