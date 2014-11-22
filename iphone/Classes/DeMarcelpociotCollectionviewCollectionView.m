/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "DeMarcelpociotCollectionviewCollectionView.h"
#import "TiUIListSectionProxy.h"
#import "DeMarcelpociotCollectionviewCollectionItem.h"
#import "DeMarcelpociotCollectionviewCollectionItemProxy.h"
#import "TiUILabelProxy.h"
#import "TiUISearchBarProxy.h"
#ifdef USE_TI_UIREFRESHCONTROL
#import "TiUIRefreshControlProxy.h"
#endif

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
    UICollectionViewController *tableController;
    UISearchDisplayController *searchController;

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

    BOOL caseInsensitiveSearch;
    NSString* _searchString;
    BOOL searchActive;
    BOOL keepSectionsInSearch;
    NSMutableArray* _searchResults;
    UIEdgeInsets _defaultSeparatorInsets;
    
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
    RELEASE_TO_NIL(tableController);
    RELEASE_TO_NIL(searchController);
    RELEASE_TO_NIL(sectionTitles);
    RELEASE_TO_NIL(sectionIndices);
    RELEASE_TO_NIL(filteredTitles);
    RELEASE_TO_NIL(filteredIndices);
    RELEASE_TO_NIL(_measureProxies);
#ifdef USE_TI_UIREFRESHCONTROL
    RELEASE_TO_NIL(_refreshControlProxy);
#endif
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
    if (_collectionView == nil) {
        UICollectionViewFlowLayout* layout = [[UICollectionViewFlowLayout alloc] init];

        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _collectionView.bounces = YES;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;

        id backgroundColor = [self.proxy valueForKey:@"backgroundColor"];
        _collectionView.backgroundColor = [[TiUtils colorValue:backgroundColor] color];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tapGestureRecognizer.delegate = self;
        [_collectionView addGestureRecognizer:tapGestureRecognizer];
        [tapGestureRecognizer release];

        [self configureHeaders];
    }
    if ([_collectionView superview] != self) {
        [self addSubview:_collectionView];
    }
    return _collectionView;
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    [_collectionView reloadData];
    [super frameSizeChanged:frame bounds:bounds];
    
    if (_headerViewProxy != nil) {
        [_headerViewProxy parentSizeWillChange];
    }
    if (_footerViewProxy != nil) {
        [_footerViewProxy parentSizeWillChange];
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

#pragma mark - Helper Methods

-(CGFloat)computeRowWidth:(UICollectionView*)tableView
{
    if (tableView == nil) {
        return 0;
    }
    CGFloat rowWidth = tableView.bounds.size.width;
    
    // Apple does not provide a good way to get information about the index sidebar size
    // in the event that it exists - it silently resizes row content which is "flexible width"
    // but this is not useful for us. This is a problem when we have Ti.UI.SIZE/FILL behavior
    // on row contents, which rely on the height of the row to be accurately precomputed.
    //
    // The following is unreliable since it uses a private API name, but one which has existed
    // since iOS 3.0. The alternative is to grab a specific subview of the tableview itself,
    // which is more fragile.
    if ((sectionTitles == nil) || (tableView != _collectionView) ) {
        return rowWidth;
    }
    NSArray* subviews = [tableView subviews];
    if ([subviews count] > 0) {
        // Obfuscate private class name
        Class indexview = NSClassFromString([@"UITableView" stringByAppendingString:@"Index"]);
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
-(NSIndexPath*)pathForSearchPath:(NSIndexPath*)indexPath
{
    if (_searchResults != nil) {
        NSArray* sectionResults = [_searchResults objectAtIndex:indexPath.section];
        return [sectionResults objectAtIndex:indexPath.row];
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

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSUInteger sectionCount = 0;
    
    sectionCount = [self.listViewProxy.sectionCount unsignedIntegerValue];
    NSLog(@"[INFO] Section count: %i", sectionCount);
    return MAX(0,sectionCount);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    DeMarcelpociotCollectionviewCollectionSectionProxy* theSection = [self.listViewProxy sectionForIndex:section];
    if (theSection != nil) {
    NSLog(@"[INFO] Item count: %i", theSection.itemCount);
        return theSection.itemCount;
    }
    NSLog(@"[INFO] Item count: 0");
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath* realIndexPath = [self pathForSearchPath:indexPath];
    DeMarcelpociotCollectionviewCollectionSectionProxy* theSection = [self.listViewProxy sectionForIndex:realIndexPath.section];
    NSInteger maxItem = 0;
    
    maxItem = theSection.itemCount;
    
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
{
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
    CGRect minimumContentRect = [_collectionView bounds];
    InsetScrollViewForKeyboard(_collectionView,keyboardTop,minimumContentRect.size.height + minimumContentRect.origin.y);
}

-(void)scrollToShowView:(TiUIView *)firstResponderView withKeyboardHeight:(CGFloat)keyboardTop
{
    if ([_collectionView isScrollEnabled]) {
        CGRect minimumContentRect = [_collectionView bounds];
        
        CGRect responderRect = [self convertRect:[firstResponderView bounds] fromView:firstResponderView];
        CGPoint offsetPoint = [_collectionView contentOffset];
        responderRect.origin.x += offsetPoint.x;
        responderRect.origin.y += offsetPoint.y;
        
        OffsetScrollViewForRect(_collectionView,keyboardTop,minimumContentRect.size.height + minimumContentRect.origin.y,responderRect);
    }
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
    return width;
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