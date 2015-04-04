/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "DeMarcelpociotCollectionviewModule.h"
#import "DeMarcelpociotCollectionviewCollectionView.h"
#import "TiUIListSectionProxy.h"
#import "DeMarcelpociotCollectionviewCollectionItem.h"
#import "DeMarcelpociotCollectionviewCollectionItemProxy.h"
#import "TiUILabelProxy.h"
#import "TiUISearchBarProxy.h"
#import "M13ContextMenuItemIOS7.h"
#import "DeMarcelpociotCollectionviewHeaderFooterReusableView.h"
#import "ImageLoader.h"
#ifdef USE_TI_UIREFRESHCONTROL
#import "TiUIRefreshControlProxy.h"

#endif

#define DEFAULT_SECTION_HEADERFOOTER_HEIGHT 40.0

@interface DeMarcelpociotCollectionviewCollectionView ()
@property (nonatomic, readonly) DeMarcelpociotCollectionviewCollectionViewProxy *listViewProxy;
@property (nonatomic,copy,readwrite) NSString * searchString;
@end

static TiViewProxy * FindViewProxyWithBindIdContainingPoint(UIView *view, CGPoint point);

@implementation DeMarcelpociotCollectionviewCollectionView {
    UICollectionView *_collectionView;
    NSDictionary *_templates;
    id _defaultItemTemplate;

    TiDimension _rowHeight;
    TiViewProxy *_headerViewProxy;
    TiViewProxy *_searchWrapper;
    TiViewProxy *_headerWrapper;
    TiViewProxy *_footerViewProxy;
    TiViewProxy *_pullViewProxy;
    
#ifdef USE_TI_UIREFRESHCONTROL
    TiUIRefreshControlProxy* _refreshControlProxy;
#endif

    TiUISearchBarProxy *searchViewProxy;
    UICollectionViewController *collectionController;
    DeMarcelpociotSearchDisplayController *searchController;
    
    M13ContextMenu * contextMenu;
    
    NSMutableArray * sectionTitles;
    NSMutableArray * sectionIndices;
    NSMutableArray * filteredTitles;
    NSMutableArray * filteredIndices;

    UIView *_pullViewWrapper;
    CGFloat pullThreshhold;

    BOOL pullActive;
    CGPoint tapPoint;
    BOOL editing;
    BOOL pruneSections;
    
    BOOL showContextMenu;

    BOOL caseInsensitiveSearch;
    NSString* _searchString;
    BOOL searchActive;
    BOOL keepSectionsInSearch;
    NSMutableArray* _searchResults;
    UIEdgeInsets _defaultSeparatorInsets;
    
    UILongPressGestureRecognizer *longPress;
    
    NSMutableDictionary* _measureProxies;
}

- (id)init
{
    self = [super init];
    if (self) {
        _defaultItemTemplate = [[NSNumber numberWithUnsignedInteger:UITableViewCellStyleDefault] retain];
        _defaultSeparatorInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (void)dealloc
{
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
    [_collectionView release];
    [_templates release];
    [_defaultItemTemplate release];
    [_headerViewProxy setProxyObserver:nil];
    [_footerViewProxy setProxyObserver:nil];
    [_pullViewProxy setProxyObserver:nil];
    RELEASE_TO_NIL(_searchString);
    RELEASE_TO_NIL(_searchResults);
    RELEASE_TO_NIL(_pullViewWrapper);
    RELEASE_TO_NIL(_pullViewProxy);
    RELEASE_TO_NIL(_headerViewProxy);
    RELEASE_TO_NIL(_searchWrapper);
    RELEASE_TO_NIL(_headerWrapper)
    RELEASE_TO_NIL(_footerViewProxy);
    RELEASE_TO_NIL(searchViewProxy);
    RELEASE_TO_NIL(collectionController);
    RELEASE_TO_NIL(searchController);
    RELEASE_TO_NIL(sectionTitles);
    RELEASE_TO_NIL(sectionIndices);
    RELEASE_TO_NIL(filteredTitles);
    RELEASE_TO_NIL(filteredIndices);
    RELEASE_TO_NIL(_measureProxies);
#ifdef USE_TI_UIREFRESHCONTROL
    RELEASE_TO_NIL(_refreshControlProxy);
#endif
    
    contextMenu.delegate = nil;
    RELEASE_TO_NIL(contextMenu);
    
    RELEASE_TO_NIL(longPress);
    [super dealloc];
}

-(TiViewProxy*)initWrapperProxy
{
    TiViewProxy* theProxy = [[TiViewProxy alloc] init];
    LayoutConstraint* viewLayout = [theProxy layoutProperties];
    viewLayout->width = TiDimensionAutoFill;
    viewLayout->height = TiDimensionAutoSize;
    return theProxy;
}

-(void)setHeaderFooter:(TiViewProxy*)theProxy isHeader:(BOOL)header
{
    NSLog(@"[INFO] setHeaderFooter called");
    [theProxy setProxyObserver:self];
    
    [theProxy windowWillOpen];
    [theProxy setParentVisible:YES];
    [theProxy windowDidOpen];
}

-(void)configureFooter
{
    if (_footerViewProxy == nil) {
        _footerViewProxy = [self initWrapperProxy];
        [self setHeaderFooter:_footerViewProxy isHeader:NO];
    }
    
}

-(void)configureHeaders
{
    NSLog(@"[INFO] configureHeaders called");
    
    _headerViewProxy = [self initWrapperProxy];
    LayoutConstraint* viewLayout = [_headerViewProxy layoutProperties];
    viewLayout->layoutStyle = TiLayoutRuleVertical;
    [self setHeaderFooter:_headerViewProxy isHeader:YES];
    
    _searchWrapper = [self initWrapperProxy];
    _headerWrapper = [self initWrapperProxy];

    [_headerViewProxy add:_searchWrapper];
    [_headerViewProxy add:_headerWrapper];
    
}

- (UICollectionView *)collectionView
{
    LayoutType layoutType = [TiUtils intValue:[[self proxy] valueForKey:@"layout"] def:kLayoutTypeGrid];
    if (_collectionView == nil) {
        
        if( layoutType == kLayoutTypeWaterfall )
        {
            CHTCollectionViewWaterfallLayout* layout = [[CHTCollectionViewWaterfallLayout alloc] init];
            layout.columnCount = [TiUtils intValue:[self.proxy valueForUndefinedKey:@"columnCount"] def:2];
            layout.minimumColumnSpacing = [TiUtils intValue:[self.proxy valueForUndefinedKey:@"minimumColumnSpacing"] def:2];
            layout.minimumInteritemSpacing = [TiUtils intValue:[self.proxy valueForUndefinedKey:@"minimumInteritemSpacing"] def:2];
            layout.itemRenderDirection = [TiUtils intValue:[self.proxy valueForUndefinedKey:@"renderDirection"] def:CHTCollectionViewWaterfallLayoutItemRenderDirectionLeftToRight];
            _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        } else {
            UICollectionViewFlowLayout* layout = [[UICollectionViewFlowLayout alloc] init];
            _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        }
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _collectionView.bounces = YES;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        
        [_collectionView registerClass:[DeMarcelpociotCollectionviewHeaderFooterReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
        
        [_collectionView registerClass:[DeMarcelpociotCollectionviewHeaderFooterReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView"];

        id backgroundColor = [self.proxy valueForKey:@"backgroundColor"];
        _collectionView.backgroundColor = [[TiUtils colorValue:backgroundColor] color];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tapGestureRecognizer.delegate = self;
        [_collectionView addGestureRecognizer:tapGestureRecognizer];
        [tapGestureRecognizer release];

        [self configureHeaders];
        
        // Create context menu
        showContextMenu = [TiUtils boolValue:[self.proxy valueForUndefinedKey:@"showContextMenu"]];
        
        //Create the items
        NSMutableArray *contextMenuItems = [[NSMutableArray alloc] init];
        if( showContextMenu  )
        {

            NSArray *_menuItems = [self.proxy valueForUndefinedKey:@"contextMenuItems"];
            ENSURE_ARRAY( _menuItems );
            for( NSDictionary* contextItem in _menuItems )
            {
                UIImage* unselectedIcon = [TiUtils image:[contextItem valueForKey:@"unselected"] proxy:self.proxy];
                UIImage* selectedIcon   = [TiUtils image:[contextItem valueForKey:@"selected"] proxy:self.proxy];
                M13ContextMenuItemIOS7 *menuItem = [[M13ContextMenuItemIOS7 alloc] initWithUnselectedIcon:unselectedIcon selectedIcon:selectedIcon];
                menuItem.tintColor  = [[TiUtils colorValue:[contextItem valueForKey:@"tintColor"]] color];
                [contextMenuItems addObject:menuItem];
            }
        }
        
        contextMenu = [[M13ContextMenu alloc] initWithMenuItems:contextMenuItems];
        contextMenu.delegate = self;
        if( showContextMenu )
        {
            contextMenu.originationCircleStrokeColor = [[TiUtils colorValue:[self.proxy valueForKey:@"contextMenuStrokeColor"]] color];
            //Create the gesture recognizer
            longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:contextMenu action:@selector(showMenuUponActivationOfGetsure:)];
            [_collectionView addGestureRecognizer:longPress];
        }
    }
    
    if ([_collectionView superview] != self) {
        [self addSubview:_collectionView];
    }
    
    return _collectionView;
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake([TiUtils intValue:[self.proxy valueForKey:@"topInset"] def:0], [TiUtils intValue:[self.proxy valueForKey:@"leftInset"] def:0], [TiUtils intValue:[self.proxy valueForKey:@"bottomInset"] def:0], [TiUtils intValue:[self.proxy valueForKey:@"rightInset"] def:0]); // top, left, bottom, right
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    NSLog(@"[INFO] frameSizeChanged");
    if (![searchController isActive]) {
        NSLog(@"[INFO] frameSizeChanged:search !isActive");
        [searchViewProxy ensureSearchBarHeirarchy];
        if (_searchWrapper != nil) {
            CGFloat rowWidth = [self computeRowWidth:_collectionView];
            if (rowWidth > 0) {
                CGFloat right = _collectionView.bounds.size.width - rowWidth;
                [_searchWrapper layoutProperties]->right = TiDimensionDip(right);
            }
        }
    }
    else {
        NSLog(@"[INFO] frameSizeChanged:search isActive");
        [UIView setAnimationsEnabled:NO];
        [_collectionView performBatchUpdates:^{
            [_collectionView reloadData];
        } completion:^(BOOL finished) {
            [UIView setAnimationsEnabled:YES];
        }];
    }
    
    [super frameSizeChanged:frame bounds:bounds];
    
    if (_headerViewProxy != nil) {
        [_headerViewProxy parentSizeWillChange];
    }
    if (_footerViewProxy != nil) {
        [_footerViewProxy parentSizeWillChange];
    }
    
    if (_pullViewWrapper != nil) { 
        _pullViewWrapper.frame = CGRectMake(0.0f, 0.0f - bounds.size.height, bounds.size.width, bounds.size.height); 
        [_pullViewProxy parentSizeWillChange]; 
    } 
    
}

- (id)accessibilityElement
{
	return self.collectionView;
}

- (DeMarcelpociotCollectionviewCollectionViewProxy *)listViewProxy
{
	return (DeMarcelpociotCollectionviewCollectionViewProxy *)self.proxy;
}


- (void) updateIndicesForVisibleRows
{
    NSLog(@"[INFO] updateIndicesForVisibleRows");
    if (_collectionView == nil || [self isSearchActive]) {
        return;
    }
    
    NSArray* visibleRows = [_collectionView indexPathsForVisibleItems];
    [visibleRows enumerateObjectsUsingBlock:^(NSIndexPath *vIndexPath, NSUInteger idx, BOOL *stop) {
        UICollectionViewCell* theCell = [_collectionView cellForItemAtIndexPath:vIndexPath];
        if ([theCell isKindOfClass:[DeMarcelpociotCollectionviewCollectionItem class]]) {
            ((DeMarcelpociotCollectionviewCollectionItem*)theCell).proxy.indexPath = vIndexPath;
        }
    }];
}

-(void)proxyDidRelayout:(id)sender
{
    TiThreadPerformOnMainThread(^{
        if (sender == _headerViewProxy) {
            //UIView* headerView = [[self tableView] tableHeaderView];
            //[headerView setFrame:[headerView bounds]];
            //[[self tableView] setTableHeaderView:headerView];
            [((DeMarcelpociotCollectionviewCollectionViewProxy*)[self proxy]) contentsWillChange];
        }
        else if (sender == _footerViewProxy) {
            //UIView *footerView = [[self tableView] tableFooterView];
            //[footerView setFrame:[footerView bounds]];
            //[[self tableView] setTableFooterView:footerView];
            [((DeMarcelpociotCollectionviewCollectionViewProxy*)[self proxy]) contentsWillChange];
        }
        else if (sender == _pullViewProxy) {
            pullThreshhold = ([_pullViewProxy view].frame.origin.y - _pullViewWrapper.bounds.size.height);
        } 
    },NO);
}

-(TiUIView*)sectionView:(NSInteger)section forLocation:(NSString*)location section:(DeMarcelpociotCollectionviewCollectionSectionProxy**)sectionResult
{
    DeMarcelpociotCollectionviewCollectionSectionProxy *proxy = [self.listViewProxy sectionForIndex:section];
    //In the event that proxy is nil, this all flows out to returning nil safely anyways.
    if (sectionResult!=nil) {
        *sectionResult = proxy;
    }
    TiViewProxy* viewproxy = [proxy valueForKey:location];
    if (viewproxy!=nil && [viewproxy isKindOfClass:[TiViewProxy class]]) {
        LayoutConstraint *viewLayout = [viewproxy layoutProperties];
        //If height is not dip, explicitly set it to SIZE
        if (viewLayout->height.type != TiDimensionTypeDip) {
            viewLayout->height = TiDimensionAutoSize;
        }
        
        TiUIView* theView = [viewproxy view];
        if (![viewproxy viewAttached]) {
            [viewproxy windowWillOpen];
            [viewproxy willShow];
            [viewproxy windowDidOpen];
        }
        return theView;
    }
    return nil;
}

#pragma mark - M13ContextMenuDelegate

- (BOOL)shouldShowContextMenu:(M13ContextMenu *)contextMenu atPoint:(CGPoint)point
{
    if( showContextMenu == NO )
    {
        return NO;
    }
    
    NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:point];
    UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    return cell != nil;
}

- (void)contextMenu:(M13ContextMenu *)contextMenu atPoint:(CGPoint)point didSelectItemAtIndex:(NSInteger)index
{
    NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:point];
    
    [self.proxy fireEvent:@"contextMenuClick" withObject:[NSDictionary dictionaryWithObjectsAndKeys:NUMINT(index),@"index",NUMINT(indexPath.row),@"itemIndex",NUMINT(indexPath.section), @"sectionIndex",nil]];
}


#pragma mark - Helper Methods

-(CGFloat)computeRowWidth:(UICollectionView*)collectionView
{
    if (collectionView == nil) {
        return 0;
    }
    CGFloat rowWidth = collectionView.bounds.size.width;
    
    // Apple does not provide a good way to get information about the index sidebar size
    // in the event that it exists - it silently resizes row content which is "flexible width"
    // but this is not useful for us. This is a problem when we have Ti.UI.SIZE/FILL behavior
    // on row contents, which rely on the height of the row to be accurately precomputed.
    //
    // The following is unreliable since it uses a private API name, but one which has existed
    // since iOS 3.0. The alternative is to grab a specific subview of the tableview itself,
    // which is more fragile.
    if ((sectionTitles == nil) || (collectionView != _collectionView) ) {
        return rowWidth;
    }
    NSArray* subviews = [collectionView subviews];
    if ([subviews count] > 0) {
        // Obfuscate private class name
        Class indexview = NSClassFromString([@"UICollectionView" stringByAppendingString:@"Index"]);
        for (UIView* view in subviews) {
            if ([view isKindOfClass:indexview]) {
                rowWidth -= [view frame].size.width;
            }
        }
    }
    
    return floorf(rowWidth);
}

-(id)valueWithKey:(NSString*)key atIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary *item = [[self.listViewProxy sectionForIndex:indexPath.section] itemAtIndex:indexPath.row];
    id propertiesValue = [item objectForKey:@"properties"];
    NSDictionary *properties = ([propertiesValue isKindOfClass:[NSDictionary class]]) ? propertiesValue : nil;
    id theValue = [properties objectForKey:key];
    if (theValue == nil) {
        id templateId = [item objectForKey:@"template"];
        if (templateId == nil) {
            templateId = _defaultItemTemplate;
        }
        if (![templateId isKindOfClass:[NSNumber class]]) {
            TiViewTemplate *template = [_templates objectForKey:templateId];
            theValue = [template.properties objectForKey:key];
        }
    }
    
    return theValue;
}

-(void)buildResultsForSearchText
{
    NSLog(@"[INFO] buildResultsForSearchText");
    searchActive = ([self.searchString length] > 0);
    RELEASE_TO_NIL(filteredIndices);
    RELEASE_TO_NIL(filteredTitles);
    if (searchActive) {
        BOOL hasResults = NO;
        //Initialize
        if(_searchResults == nil) {
            _searchResults = [[NSMutableArray alloc] init];
        }
        //Clear Out
        [_searchResults removeAllObjects];
        
        //Search Options
        NSStringCompareOptions searchOpts = (caseInsensitiveSearch ? NSCaseInsensitiveSearch : 0);
        
        NSUInteger maxSection = [[self.listViewProxy sectionCount] unsignedIntegerValue];
        NSMutableArray* singleSection = keepSectionsInSearch ? nil : [[NSMutableArray alloc] init];
        for (int i = 0; i < maxSection; i++) {
            NSMutableArray* thisSection = keepSectionsInSearch ? [[NSMutableArray alloc] init] : nil;
            NSUInteger maxItems = [[self.listViewProxy sectionForIndex:i] itemCount];
            for (int j = 0; j < maxItems; j++) {
                NSIndexPath* thePath = [NSIndexPath indexPathForRow:j inSection:i];
                id theValue = [self valueWithKey:@"searchableText" atIndexPath:thePath];
                if (theValue!=nil && [[TiUtils stringValue:theValue] rangeOfString:self.searchString options:searchOpts].location != NSNotFound) {
                    (thisSection != nil) ? [thisSection addObject:thePath] : [singleSection addObject:thePath];
                    hasResults = YES;
                }
            }
            if (thisSection != nil) {
                if ([thisSection count] > 0) {
                    [_searchResults addObject:thisSection];
                    
                    if (sectionTitles != nil && sectionIndices != nil) {
                        NSNumber* theIndex = [NSNumber numberWithInt:i];
                        if ([sectionIndices containsObject:theIndex]) {
                            id theTitle = [sectionTitles objectAtIndex:[sectionIndices indexOfObject:theIndex]];
                            if (filteredTitles == nil) {
                                filteredTitles = [[NSMutableArray alloc] init];
                            }
                            if (filteredIndices == nil) {
                                filteredIndices = [[NSMutableArray alloc] init];
                            }
                            [filteredTitles addObject:theTitle];
                            [filteredIndices addObject:[NSNumber numberWithUnsignedInteger:([_searchResults count] -1)] ];
                        }
                    }
                }
                [thisSection release];
            }
        }
        if (singleSection != nil) {
            if ([singleSection count] > 0) {
                [_searchResults addObject:singleSection];
            }
            [singleSection release];
        }
        if (!hasResults) {
            if ([(TiViewProxy*)self.proxy _hasListeners:@"noresults" checkParent:NO]) {
                [self.proxy fireEvent:@"noresults" withObject:nil propagate:NO reportSuccess:NO errorCode:0 message:nil];
            }
        }
        NSString* res = hasResults ? @"YES" : @"FALSE";
        NSLog(@"[INFO] buildResultsForSearchText:Results -> %@", res);
    } else {
        RELEASE_TO_NIL(_searchResults);
    }
}

-(BOOL) isSearchActive
{
    return searchActive || [searchController isActive];
}

- (void)updateSearchResults:(id)unused
{
    if (searchActive) {
        [self buildResultsForSearchText];
    }
    [_collectionView reloadData];
    if ([searchController isActive]) {
        [[searchController searchResultsTableView] reloadData];
    }
}

-(NSIndexPath*)pathForSearchPath:(NSIndexPath*)indexPath
{
    if (_searchResults != nil) {
        NSArray* sectionResults = [_searchResults objectAtIndex:indexPath.section];
        
        if([sectionResults count] > indexPath.row) {
            return [sectionResults objectAtIndex:indexPath.row];
        }
    }
    return indexPath;
}

-(NSInteger)sectionForSearchSection:(NSInteger)section
{
    if (_searchResults != nil) {
        NSArray* sectionResults = [_searchResults objectAtIndex:section];
        NSIndexPath* thePath = [sectionResults objectAtIndex:0];
        return thePath.section;
    }
    return section;
}

#pragma mark - Public API

-(void)setRefreshControl_:(id)args
{
#ifdef USE_TI_UIREFRESHCONTROL
    ENSURE_SINGLE_ARG_OR_NIL(args,TiUIRefreshControlProxy);
    [[_refreshControlProxy control] removeFromSuperview];
    RELEASE_TO_NIL(_refreshControlProxy);
    [[self proxy] replaceValue:args forKey:@"refreshControl" notification:NO];
    if (args != nil) {
        _refreshControlProxy = [args retain];
        [[self collectionView] addSubview:[_refreshControlProxy control]];
    }
#endif
}

-(void)setPullView_:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args,TiViewProxy);
    if (args == nil) {
        [_pullViewProxy setProxyObserver:nil];
        [_pullViewProxy windowWillClose];
        [_pullViewWrapper removeFromSuperview];
        [_pullViewProxy windowDidClose];
        RELEASE_TO_NIL(_pullViewWrapper);
        RELEASE_TO_NIL(_pullViewProxy);
    } else {
        if ([self collectionView].bounds.size.width==0)
        {
            [self performSelector:@selector(setPullView_:) withObject:args afterDelay:0.1];
            return;
        }
        if (_pullViewProxy != nil) {
            [_pullViewProxy setProxyObserver:nil];
            [_pullViewProxy windowWillClose];
            [_pullViewProxy windowDidClose];
            RELEASE_TO_NIL(_pullViewProxy);
        }
        if (_pullViewWrapper == nil) {
            _pullViewWrapper = [[UIView alloc] init];
            [_collectionView addSubview:_pullViewWrapper];
        }
        CGSize refSize = _collectionView.bounds.size;
        [_pullViewWrapper setFrame:CGRectMake(0.0, 0.0 - refSize.height, refSize.width, refSize.height)];
        _pullViewProxy = [args retain];
        TiColor* pullBgColor = [TiUtils colorValue:[_pullViewProxy valueForUndefinedKey:@"pullBackgroundColor"]];
        _pullViewWrapper.backgroundColor = ((pullBgColor == nil) ? [UIColor lightGrayColor] : [pullBgColor color]);
        LayoutConstraint *viewLayout = [_pullViewProxy layoutProperties];
        //If height is not dip, explicitly set it to SIZE
        if (viewLayout->height.type != TiDimensionTypeDip) {
            viewLayout->height = TiDimensionAutoSize;
        }
        //If bottom is not dip set it to 0
        if (viewLayout->bottom.type != TiDimensionTypeDip) {
            viewLayout->bottom = TiDimensionZero;
        }
        //Remove other vertical positioning constraints
        viewLayout->top = TiDimensionUndefined;
        viewLayout->centerY = TiDimensionUndefined;
        
        [_pullViewProxy setProxyObserver:self];
        [_pullViewProxy windowWillOpen];
        [_pullViewWrapper addSubview:[_pullViewProxy view]];
        _pullViewProxy.parentVisible = YES;
        [_pullViewProxy refreshSize];
        [_pullViewProxy willChangeSize];
        [_pullViewProxy windowDidOpen];
    }
    
}

-(void)setKeepSectionsInSearch_:(id)args
{
    if (searchViewProxy == nil) {
        keepSectionsInSearch = [TiUtils boolValue:args def:NO];
        if (searchActive) {
            [self buildResultsForSearchText];
            [_collectionView reloadData];
        }
    } else {
        keepSectionsInSearch = NO;
    }
}

-(void)setContentInsets_:(id)value withObject:(id)props
{
    UIEdgeInsets insets = [TiUtils contentInsets:value];
    BOOL animated = [TiUtils boolValue:@"animated" properties:props def:NO];
    void (^setInset)(void) = ^{
        [_collectionView setContentInset:insets];
    };
    if (animated) {
        double duration = [TiUtils doubleValue:@"duration" properties:props def:300]/1000;
        [UIView animateWithDuration:duration animations:setInset];
    }
    else {
        setInset();
    }
}

- (void)setDictTemplates_:(id)args
{
    ENSURE_TYPE_OR_NIL(args,NSDictionary);
    [[self proxy] replaceValue:args forKey:@"dictTemplates" notification:NO];
    [_templates release];
    _templates = [args copy];
    RELEASE_TO_NIL(_measureProxies);
    _measureProxies = [[NSMutableDictionary alloc] init];
    NSEnumerator *enumerator = [_templates keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        id template = [_templates objectForKey:key];
        if (template != nil) {
            DeMarcelpociotCollectionviewCollectionItemProxy *theProxy = [[DeMarcelpociotCollectionviewCollectionItemProxy alloc] initWithListViewProxy:self.listViewProxy inContext:self.listViewProxy.pageContext];
            
            NSString *cellIdentifier = [key isKindOfClass:[NSNumber class]] ? [NSString stringWithFormat:@"TiUIListView__internal%@", key]: [key description];
            NSLog(@"[INFO] Registering class for identifier %@", cellIdentifier);
            [_collectionView registerClass:[DeMarcelpociotCollectionviewCollectionItem class] forCellWithReuseIdentifier:cellIdentifier];
            /**
             DeMarcelpociotCollectionviewCollectionItem* cell = [[DeMarcelpociotCollectionviewCollectionItem alloc] initWithProxy:theProxy reuseIdentifier:@"__measurementCell__"];
             [theProxy unarchiveFromTemplate:template];
             [_measureProxies setObject:cell forKey:key];
             [theProxy setIndexPath:[NSIndexPath indexPathForRow:-1 inSection:-1]];
             [cell release];
             [theProxy release];
             */
        }
    }
    if (_collectionView != nil) {
        [_collectionView reloadData];
    }
}


-(void)setPruneSectionsOnEdit_:(id)args
{
    pruneSections = [TiUtils boolValue:args def:NO];
}

-(void)setCanScroll_:(id)args
{
    UICollectionView *table = [self collectionView];
    [table setScrollEnabled:[TiUtils boolValue:args def:YES]];
}

- (void)setDefaultItemTemplate_:(id)args
{
	if (![args isKindOfClass:[NSString class]] && ![args isKindOfClass:[NSNumber class]]) {
		ENSURE_TYPE_OR_NIL(args,NSString);
	}
	[_defaultItemTemplate release];
	_defaultItemTemplate = [args copy];
	if (_collectionView != nil) {
		[_collectionView reloadData];
	}	
}


- (void)setBackgroundColor_:(id)arg
{
	if (_collectionView != nil) {
        _collectionView.backgroundColor = [TiUtils colorValue:arg].color;
	}
}

-(void)setHeaderView_:(id)args
{
    
    ENSURE_SINGLE_ARG_OR_NIL(args,TiViewProxy);
    [self collectionView];
    [_headerWrapper removeAllChildren:nil];
    if (args!=nil) {
        [_headerWrapper add:(TiViewProxy*) args];
        NSLog(@"[INFO] setHeaderView_ called: %@", ((TiViewProxy*) args).view);
    }
}

- (void)setScrollIndicatorStyle_:(id)value
{
	[self.collectionView setIndicatorStyle:[TiUtils intValue:value def:UIScrollViewIndicatorStyleDefault]];
}

- (void)setWillScrollOnStatusTap_:(id)value
{
	[self.collectionView setScrollsToTop:[TiUtils boolValue:value def:YES]];
}

- (void)setShowVerticalScrollIndicator_:(id)value
{
	[self.collectionView setShowsVerticalScrollIndicator:[TiUtils boolValue:value]];
}

-(void)setAllowsSelection_:(id)value
{
    [[self collectionView] setAllowsSelection:[TiUtils boolValue:value]];
}

#pragma mark - Search Support
-(void)setCaseInsensitiveSearch_:(id)args
{
    caseInsensitiveSearch = [TiUtils boolValue:args def:YES];
    if (searchActive) {
        //[self buildResultsForSearchText];
        if ([searchController isActive]) {
            [[searchController searchResultsCollectionView] reloadData];
        } else {
            [_collectionView reloadData];
        }
    }
}

-(void)setSearchText_:(id)args
{
    id searchView = [self.proxy valueForKey:@"searchView"];
    if (!IS_NULL_OR_NIL(searchView)) {
        DebugLog(@"Can not use searchText with searchView. Ignoring call.");
        return;
    }
    self.searchString = [TiUtils stringValue:args];
    [self buildResultsForSearchText];
    [_collectionView reloadData];
}

-(void)setSearchView_:(id)args
{
    ENSURE_TYPE_OR_NIL(args,TiUISearchBarProxy);
    [self collectionView];
    [searchViewProxy setDelegate:nil];
    RELEASE_TO_NIL(searchViewProxy);
    RELEASE_TO_NIL(collectionController);
    RELEASE_TO_NIL(searchController);
    [_searchWrapper removeAllChildren:nil];
    
    if (args != nil) {
        searchViewProxy = [args retain];
        [searchViewProxy setDelegate:self];
        [_searchWrapper add:searchViewProxy];
        NSLog(@"[INFO] setSearchView_ called: %@", searchViewProxy.view);
        if ([TiUtils isIOS7OrGreater]) {
            NSString *curPlaceHolder = [[searchViewProxy searchBar] placeholder];
            if (curPlaceHolder == nil) {
                [[searchViewProxy searchBar] setPlaceholder:@"Search"];
            }
        } else {
            [self initSearchController:self];
        }
        keepSectionsInSearch = NO;
    } else {
        keepSectionsInSearch = [TiUtils boolValue:[self.proxy valueForKey:@"keepSectionsInSearch"] def:NO];
    }
    
}



#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSUInteger sectionCount = 0;
    
    if (_searchResults != nil) {
        sectionCount = [_searchResults count];
    } else {
        sectionCount = [self.listViewProxy.sectionCount unsignedIntegerValue];
    }

    NSLog(@"[INFO] Section count: %i", sectionCount);
    return MAX(0,sectionCount);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (_searchResults != nil) {
        if ([_searchResults count] <= section) {
            return 0;
        }
        NSArray* theSection = [_searchResults objectAtIndex:section];
        return [theSection count];
        
    }
    else {
        DeMarcelpociotCollectionviewCollectionSectionProxy* theSection = [self.listViewProxy sectionForIndex:section];
        if (theSection != nil) {
            NSLog(@"[INFO] Item count: %i", theSection.itemCount);
            return theSection.itemCount;
        }
        NSLog(@"[INFO] Item count: 0");
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath* realIndexPath = [self pathForSearchPath:indexPath];
    DeMarcelpociotCollectionviewCollectionSectionProxy* theSection = [self.listViewProxy sectionForIndex:realIndexPath.section];
    NSInteger maxItem = 0;
    
    if (_searchResults != nil && [_searchResults count] > indexPath.section) {
        NSArray* sectionResults = [_searchResults objectAtIndex:indexPath.section];
        maxItem = [sectionResults count];
    } else {
        maxItem = theSection.itemCount;
    }
    
    NSDictionary *item = [theSection itemAtIndex:realIndexPath.row];
    id templateId = [item objectForKey:@"template"];
    if (templateId == nil) {
        templateId = _defaultItemTemplate;
    }
    NSString *cellIdentifier = [templateId isKindOfClass:[NSNumber class]] ? [NSString stringWithFormat:@"TiUIListView__internal%@", templateId]: [templateId description];
    NSLog(@"[INFO] Loading cell (Identifier: %@) section: %i - item %i", cellIdentifier, indexPath.section, indexPath.item);
    DeMarcelpociotCollectionviewCollectionItem *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if( cell.proxy == nil )
    {
        NSLog(@"[INFO] Loading proxy for cell");
        id<TiEvaluator> context = self.listViewProxy.executionContext;
        if (context == nil) {
            context = self.listViewProxy.pageContext;
        }
        DeMarcelpociotCollectionviewCollectionItemProxy *cellProxy = [[DeMarcelpociotCollectionviewCollectionItemProxy alloc] initWithListViewProxy:self.listViewProxy inContext:context];
        [cell initWithProxy:cellProxy];

        id template = [_templates objectForKey:templateId];
        if (template != nil) {
                NSLog(@"[INFO] Template found");
                [cellProxy unarchiveFromTemplate:template];
        }
        [cellProxy release];
    }
        //cellProxy = nil;
    cell.dataItem = item;
    cell.proxy.indexPath = realIndexPath;
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"[INFO] Process viewForSupplementaryElementOfKind: %@", kind);
    NSLog(@"[INFO] Test: %@", UICollectionElementKindSectionHeader);
    UICollectionReusableView *reusableview = nil;
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        DeMarcelpociotCollectionviewHeaderFooterReusableView* headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        CGFloat height = 0.0;
        CGFloat width = [self.collectionView bounds].size.width;
        TiViewProxy* viewProxy = (TiViewProxy*) _headerViewProxy;
        LayoutConstraint *viewLayout = [viewProxy layoutProperties];
        
        switch (viewLayout->height.type)
        {
            case TiDimensionTypeDip:
                NSLog(@"[INFO] height.type: %@", @"TiDimensionTypeDip");
                height += viewLayout->height.value;
                break;
            case TiDimensionTypeAuto:
            case TiDimensionTypeAutoSize:
                NSLog(@"[INFO] height.type: %@", @"TiDimensionTypeAutoSize");
                height += [viewProxy autoHeightForSize:[self.collectionView bounds].size];
                break;
            default:
                NSLog(@"[INFO] height.type: %@", @"Default");
                height+=DEFAULT_SECTION_HEADERFOOTER_HEIGHT;
                break;
        }

        NSLog(@"[INFO] _headerViewProxy HSize: %f", height);
        NSLog(@"[INFO] _headerViewProxy WSize: %f", width);

        [headerView setBounds:CGRectMake(0, 0, width, height)];
        
        [headerView addSubview:_headerViewProxy.view];
        //[_headerView.view setFrame:CGRectMake(0, 0, width, height)];
        
        NSLog(@"[INFO] reusableview frame: %@", headerView);
        
        reusableview = headerView;
        
    }
    
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        DeMarcelpociotCollectionviewHeaderFooterReusableView *footerview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        
        [reusableview addSubview:_footerViewProxy.view];
        reusableview = footerview;
    }
    
    return reusableview;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    //Let the cell configure its background
    [(DeMarcelpociotCollectionviewCollectionItem*)cell configureCellBackground];
    
    if ([TiUtils isIOS7OrGreater]) {
        NSIndexPath* realPath = [self pathForSearchPath:indexPath];
        id tintValue = [self valueWithKey:@"tintColor" atIndexPath:realPath];
        UIColor* theTint = [[TiUtils colorValue:tintValue] color];
        if (theTint == nil) {
            theTint = [collectionView tintColor];
        }
        [cell performSelector:@selector(setTintColor:) withObject:theTint];
    }
    
    if (searchActive || (collectionView != _collectionView)) {
        return;
    } else {
        //Tell the proxy about the cell to be displayed for marker event
        [self.listViewProxy willDisplayCell:indexPath];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    NSLog(@"[INFO] referenceSizeForHeaderInSection");
    NSInteger realSection = section;
    
    if (searchActive) {
        if (keepSectionsInSearch && ([_searchResults count] > 0) ) {
            realSection = [self sectionForSearchSection:section];
        } else {
            return CGSizeZero;
        }
    }
    
    DeMarcelpociotCollectionviewCollectionSectionProxy *sectionProxy = [self.listViewProxy sectionForIndex:realSection];
    TiUIView *view = [self sectionView:realSection forLocation:@"headerView" section:nil];
    
    CGFloat height = 0.0;
    CGFloat width = 0.0;
    if (view != nil) {
        NSLog(@"[INFO] original section header size: %@", view);
        TiViewProxy* viewProxy = (TiViewProxy*) [view proxy];
        LayoutConstraint *viewLayout = [viewProxy layoutProperties];
        //NSLog(@"[INFO] viewLayout: %@", viewLayout);
        switch (viewLayout->height.type)
        {
            case TiDimensionTypeDip:
                height += viewLayout->height.value;
                break;
            case TiDimensionTypeAuto:
            case TiDimensionTypeAutoSize:
                height += [viewProxy autoHeightForSize:[self.collectionView bounds].size];
                break;
            default:
                height+=DEFAULT_SECTION_HEADERFOOTER_HEIGHT;
                break;
        }
        width = [self.collectionView bounds].size.width;
        
        NSLog(@"[INFO] HSize: %f", height);
        NSLog(@"[INFO] WSize: %f", width);
        [view setBounds:CGRectMake(0, 0, width, height)];
        //[view setFrame:CGRectMake(0, 0, width, height)];
        NSLog(@"[INFO] section header size: %@", view);
        
        return CGSizeMake(width, height);
    }
    else {
        TiViewProxy* viewProxy = (TiViewProxy*) _headerViewProxy;
        LayoutConstraint *viewLayout = [viewProxy layoutProperties];
        switch (viewLayout->height.type)
        {
            case TiDimensionTypeDip:
                height += viewLayout->height.value;
                break;
            case TiDimensionTypeAuto:
            case TiDimensionTypeAutoSize:
                height += [viewProxy autoHeightForSize:[self.collectionView bounds].size];
                break;
            default:
                height+=DEFAULT_SECTION_HEADERFOOTER_HEIGHT;
                break;
        }

    }
    NSLog(@"[INFO] header height: %f", height);
    NSLog(@"[INFO] header height: %f", [_headerViewProxy autoHeightForSize:[self.collectionView bounds].size]);
    NSLog(@"[INFO] header height: %f", [_headerViewProxy autoHeightForSize:[_headerViewProxy.view bounds].size]);
    NSLog(@"[INFO] header size: %@", _headerViewProxy.view);
    return CGSizeMake(self.collectionView.bounds.size.width, height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    NSLog(@"[INFO] referenceSizeForFooterInSection");
    NSInteger realSection = section;
    
    if (searchActive) {
        if (keepSectionsInSearch && ([_searchResults count] > 0) ) {
            realSection = [self sectionForSearchSection:section];
        } else {
            return CGSizeZero;
        }
    }
    return _footerViewProxy.view.frame.size;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    NSLog(@"[INFO] sizeForItemAtIndexPath");
    NSIndexPath* realPath = [self pathForSearchPath:indexPath];
    
    id heightValue = [self valueWithKey:@"height" atIndexPath:realPath];
    
    CGFloat height = 100.0f;
    if (heightValue != nil) {
        height = [TiUtils dimensionValue:heightValue].value;
    }
    
    id widthValue = [self valueWithKey:@"width" atIndexPath:realPath];
    CGFloat width = 100.0f;
    if (widthValue != nil) {
        width = [TiUtils dimensionValue:widthValue].value;
    }
    NSLog(@"[INFO] Size: %@",NSStringFromCGSize(CGSizeMake(width, height)));
    return CGSizeMake(width, height);
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    DeMarcelpociotCollectionviewCollectionSectionProxy* theSection = [self.listViewProxy sectionForIndex:section];
    return [TiUtils floatValue:[theSection valueForKey:@"itemSpacing"] def:2.0];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    DeMarcelpociotCollectionviewCollectionSectionProxy* theSection = [self.listViewProxy sectionForIndex:section];
    return [TiUtils floatValue:[theSection valueForKey:@"lineSpacing"] def:2.0];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self fireClickForItemAtIndexPath:[self pathForSearchPath:indexPath] tableView:collectionView accessoryButtonTapped:NO];
}

#pragma mark - TiScrolling

-(void)keyboardDidShowAtHeight:(CGFloat)keyboardTop
{
    NSLog(@"[INFO] keyboardDidShowAtHeight");
    CGRect minimumContentRect = [_collectionView bounds];
    InsetScrollViewForKeyboard(_collectionView,keyboardTop,minimumContentRect.size.height + minimumContentRect.origin.y);
}

-(void)scrollToShowView:(TiUIView *)firstResponderView withKeyboardHeight:(CGFloat)keyboardTop
{
    NSLog(@"[INFO] scrollToShowView");
    if ([_collectionView isScrollEnabled]) {
        CGRect minimumContentRect = [_collectionView bounds];
        
        CGRect responderRect = [self convertRect:[firstResponderView bounds] fromView:firstResponderView];
        CGPoint offsetPoint = [_collectionView contentOffset];
        responderRect.origin.x += offsetPoint.x;
        responderRect.origin.y += offsetPoint.y;
        
        OffsetScrollViewForRect(_collectionView,keyboardTop,minimumContentRect.size.height + minimumContentRect.origin.y,responderRect);
    }
}

#pragma mark - ScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //Events - pull (maybe scroll later)
    if (![self.proxy _hasListeners:@"pull"]) {
        return;
    }
    
    if ( (_pullViewProxy != nil) && ([scrollView isTracking]) ) {
        if ( (scrollView.contentOffset.y < pullThreshhold) && (pullActive == NO) ) {
            pullActive = YES;
            [self.proxy fireEvent:@"pull" withObject:[NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(pullActive),@"active",nil] withSource:self.proxy propagate:NO reportSuccess:NO errorCode:0 message:nil];
        } else if ( (scrollView.contentOffset.y > pullThreshhold) && (pullActive == YES) ) {
            pullActive = NO;
            [self.proxy fireEvent:@"pull" withObject:[NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(pullActive),@"active",nil] withSource:self.proxy propagate:NO reportSuccess:NO errorCode:0 message:nil];
        }
    }
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //Events - None (maybe dragstart later)
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    //Events - pullend (maybe dragend later)
    if (![self.proxy _hasListeners:@"pullend"]) {
        return;
    }
    if ( (_pullViewProxy != nil) && (pullActive == YES) ) {
        pullActive = NO;
        
        [self.proxy fireEvent:@"pullend" withObject:nil withSource:self.proxy propagate:NO reportSuccess:NO
                    errorCode:0 message:nil];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //Events - none (maybe scrollend later)
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    //Events none (maybe scroll later)
}

#pragma mark - UISearchBarDelegate Methods
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"[INFO] searchBarShouldBeginEditing");
    if (_searchWrapper != nil) {
        [_searchWrapper layoutProperties]->right = TiDimensionDip(0);
        [_searchWrapper refreshView:nil];
        if ([TiUtils isIOS7OrGreater]) {
            [self initSearchController:self];
        }
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"[INFO] searchBarTextDidBeginEditing");
    self.searchString = (searchBar.text == nil) ? @"" : searchBar.text;
    [self buildResultsForSearchText];
    [[searchController searchResultsCollectionView] reloadData];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSLog(@"[INFO] searchBarTextDidEndEditing");
    if ([searchBar.text length] == 0) {
        self.searchString = @"";
        [self buildResultsForSearchText];
        if ([searchController isActive]) {
            [searchController setActive:NO animated:YES];
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSLog(@"[INFO] searchBar:textDidChange");
    self.searchString = (searchText == nil) ? @"" : searchText;
    [self buildResultsForSearchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"[INFO] searchBarSearchButtonClicked");
    [searchBar resignFirstResponder];
    [self makeRootViewFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    NSLog(@"[INFO] searchBarCancelButtonClicked");
    self.searchString = @"";
    [searchBar setText:self.searchString];
    [self buildResultsForSearchText];
}

#pragma mark - UISearchDisplayDelegate Methods

- (void)textDidChange:(NSString *)searchText
{
    NSLog(@"[INFO] textDidChange");
}

- (void)searchDisplayControllerWillBeginSearch:(DeMarcelpociotSearchDisplayController *)controller
{
    NSLog(@"[INFO] searchDisplayControllerWillBeginSearch");
    
}

- (void)searchDisplayControllerDidBeginSearch:(DeMarcelpociotSearchDisplayController *)controller
{
    NSLog(@"[INFO] searchDisplayControllerDidBeginSearch");
}

- (void)searchDisplayControllerWillEndSearch:(DeMarcelpociotSearchDisplayController *)controller
{
    NSLog(@"[INFO] searchDisplayControllerWillEndSearch");
}

- (void) searchDisplayControllerDidEndSearch:(DeMarcelpociotSearchDisplayController *)controller
{
    NSLog(@"[INFO] searchDisplayControllerDidEndSearch");
    self.searchString = @"";
    [self buildResultsForSearchText];
    if ([searchController isActive]) {
        [searchController setActive:NO animated:YES];
    }
    if (_searchWrapper != nil) {
        CGFloat rowWidth = floorf([self computeRowWidth:_collectionView]);
        if (rowWidth > 0) {
            CGFloat right = _collectionView.bounds.size.width - rowWidth;
            [_searchWrapper layoutProperties]->right = TiDimensionDip(right);
            [_searchWrapper refreshView:nil];
        }
    }
    //IOS7 DP3. TableView seems to be adding the searchView to
    //tableView. Bug on IOS7?
    if ([TiUtils isIOS7OrGreater]) {
        [self clearSearchController:self];
    }
    [_collectionView reloadData];
}


#pragma mark - Internal Methods

- (void)fireClickForItemAtIndexPath:(NSIndexPath *)indexPath tableView:(UICollectionView *)tableView accessoryButtonTapped:(BOOL)accessoryButtonTapped
{
	NSString *eventName = @"itemclick";
    if (![self.proxy _hasListeners:eventName]) {
		return;
	}
	DeMarcelpociotCollectionviewCollectionSectionProxy *section = [self.listViewProxy sectionForIndex:indexPath.section];
	NSDictionary *item = [section itemAtIndex:indexPath.row];
	NSMutableDictionary *eventObject = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
										section, @"section",
										NUMINT(indexPath.section), @"sectionIndex",
										NUMINT(indexPath.row), @"itemIndex",
										NUMBOOL(accessoryButtonTapped), @"accessoryClicked",
										nil];
	id propertiesValue = [item objectForKey:@"properties"];
	NSDictionary *properties = ([propertiesValue isKindOfClass:[NSDictionary class]]) ? propertiesValue : nil;
	id itemId = [properties objectForKey:@"itemId"];
	if (itemId != nil) {
		[eventObject setObject:itemId forKey:@"itemId"];
	}
	DeMarcelpociotCollectionviewCollectionItem *cell = (DeMarcelpociotCollectionviewCollectionItem *)[tableView cellForItemAtIndexPath:indexPath];
	if (cell.templateStyle == TiUIListItemTemplateStyleCustom) {
		UIView *contentView = cell.contentView;
		TiViewProxy *tapViewProxy = FindViewProxyWithBindIdContainingPoint(contentView, [tableView convertPoint:tapPoint toView:contentView]);
		if (tapViewProxy != nil) {
			[eventObject setObject:[tapViewProxy valueForKey:@"bindId"] forKey:@"bindId"];
		}
	}
	[self.proxy fireEvent:eventName withObject:eventObject];
	[eventObject release];	
}

-(CGFloat)contentWidthForWidth:(CGFloat)width
{
    NSLog(@"[INFO] contentWidthForWidth called");
    return width;
}

-(CGFloat)contentHeightForWidth:(CGFloat)width
{
    NSLog(@"[INFO] contentHeightForWidth called");
    if (_collectionView == nil) {
        return 0;
    }
    
    CGSize refSize = CGSizeMake(width, 1000);
    
    CGFloat resultHeight = 0;
    
    //Last Section rect
    NSInteger lastSectionIndex = [self numberOfSectionsInCollectionView:_collectionView] - 1;
    if (lastSectionIndex >= 0) {
        //CGRect refRect = [_collectionView rectForSection:lastSectionIndex];
        //resultHeight += refRect.size.height + refRect.origin.y;
    } else {
        //Header auto height when no sections
        if (_headerViewProxy != nil) {
            resultHeight += [_headerViewProxy autoHeightForSize:refSize];
        }
    }
    
    //Footer auto height
    if (_footerViewProxy) {
        resultHeight += [_footerViewProxy autoHeightForSize:refSize];
    }
    
    return resultHeight;
}

-(void)clearSearchController:(id)sender
{
    if (sender == self) {
        RELEASE_TO_NIL(collectionController);
        RELEASE_TO_NIL(searchController);
        [searchViewProxy ensureSearchBarHeirarchy];
    }
}

-(void)initSearchController:(id)sender
{
    NSLog(@"[INFO] initSearchController called");
    if (sender == self && collectionController == nil) {
        NSLog(@"[INFO] initSearchController begins");
        collectionController = [[UICollectionViewController alloc] init];
        [TiUtils configureController:collectionController withObject:nil];
        collectionController.collectionView = [self collectionView];
        searchController = [[DeMarcelpociotSearchDisplayController alloc] initWithSearchBar:[searchViewProxy searchBar] contentsController:collectionController];
        searchController.searchResultsDataSource = self;
        searchController.searchResultsDelegate = self;
        searchController.delegate = self;
        [searchController setActive:YES animated:YES];
    }
}

#pragma mark - UITapGestureRecognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	tapPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
	return NO;
}

- (void)handleTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
	// Never called
}

#pragma mark - Static Methods

+ (TiViewProxy*)titleViewForText:(NSString*)text inTable:(UITableView *)tableView footer:(BOOL)footer
{
    TiUILabelProxy* titleProxy = [[TiUILabelProxy alloc] init];
    [titleProxy setValue:[NSDictionary dictionaryWithObjectsAndKeys:@"17",@"fontSize",@"bold",@"fontWeight", nil] forKey:@"font"];
    [titleProxy setValue:text forKey:@"text"];
    [titleProxy setValue:@"black" forKey:@"color"];
    [titleProxy setValue:@"white" forKey:@"shadowColor"];
    [titleProxy setValue:[NSDictionary dictionaryWithObjectsAndKeys:@"0",@"x",@"1",@"y", nil] forKey:@"shadowOffset"];
    
    LayoutConstraint *viewLayout = [titleProxy layoutProperties];
    viewLayout->width = TiDimensionAutoFill;
    viewLayout->height = TiDimensionAutoSize;
    viewLayout->top = TiDimensionDip(10.0);
    viewLayout->bottom = TiDimensionDip(10.0);
    viewLayout->left = ([tableView style] == UITableViewStyleGrouped) ? TiDimensionDip(15.0) : TiDimensionDip(10.0);
    viewLayout->right = ([tableView style] == UITableViewStyleGrouped) ? TiDimensionDip(15.0) : TiDimensionDip(10.0);

    return [titleProxy autorelease];
}

@end

static TiViewProxy * FindViewProxyWithBindIdContainingPoint(UIView *view, CGPoint point)
{
	if (!CGRectContainsPoint([view bounds], point)) {
		return nil;
	}
	for (UIView *subview in [view subviews]) {
		TiViewProxy *viewProxy = FindViewProxyWithBindIdContainingPoint(subview, [view convertPoint:point toView:subview]);
		if (viewProxy != nil) {
			id bindId = [viewProxy valueForKey:@"bindId"];
			if (bindId != nil) {
				return viewProxy;
			}
		}
	}
	if ([view isKindOfClass:[TiUIView class]]) {
		TiViewProxy *viewProxy = (TiViewProxy *)[(TiUIView *)view proxy];
		id bindId = [viewProxy valueForKey:@"bindId"];
		if (bindId != nil) {
			return viewProxy;
		}
	}
	return nil;
}