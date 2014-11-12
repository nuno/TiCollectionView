/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "DeMarcelpociotCollectionviewCollectionItem.h"
#import "TiUtils.h"
#import "TiViewProxy.h"
#import "ImageLoader.h"
#import "Webcolor.h"

@implementation DeMarcelpociotCollectionviewCollectionItem {
	DeMarcelpociotCollectionviewCollectionItemProxy *_proxy;
	NSInteger _templateStyle;
	NSMutableDictionary *_initialValues;
	NSMutableDictionary *_currentValues;
	NSMutableSet *_resetKeys;
	NSDictionary *_dataItem;
	NSDictionary *_bindings;
    int _positionMask;
    BOOL _grouped;
    UIView* _bgView;
}

@synthesize templateStyle = _templateStyle;
@synthesize proxy = _proxy;
@synthesize dataItem = _dataItem;

- (id)initWithProxy:(DeMarcelpociotCollectionviewCollectionItemProxy *)proxy reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithFrame:<#(CGRect)#>]
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
		_templateStyle = TiUIListItemTemplateStyleCustom;
		_initialValues = [[NSMutableDictionary alloc] initWithCapacity:10];
		_currentValues = [[NSMutableDictionary alloc] initWithCapacity:10];
		_resetKeys = [[NSMutableSet alloc] initWithCapacity:10];
		_proxy = [proxy retain];
		_proxy.listItem = self;
    }
    return self;
}

- (void)dealloc
{
	_proxy.listItem = nil;
	[_initialValues release];
	[_currentValues release];
	[_resetKeys release];
	[_dataItem release];
	[_proxy deregisterProxy:[_proxy pageContext]];
	[_proxy release];
	[_bindings release];
	[gradientLayer release];
	[backgroundGradient release];
	[selectedBackgroundGradient release];
    [_bgView removeFromSuperview];
    [_bgView release];
	[super dealloc];
}

- (NSDictionary *)bindings
{
	if (_bindings == nil) {
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:10];
		[[self class] buildBindingsForViewProxy:_proxy intoDictionary:dict];
		_bindings = [dict copy];
		[dict release];
	}
	return _bindings;
}

- (void)prepareForReuse
{
	RELEASE_TO_NIL(_dataItem);
	[super prepareForReuse];
}

- (void)layoutSubviews
{
    if (_bgView != nil) {
        if ([_bgView superview] == nil) {
            [self.backgroundView addSubview:_bgView];
        }
        CGRect bounds = [self.backgroundView bounds];
        if ((_positionMask == TiCellBackgroundViewPositionTop) || (_positionMask == TiCellBackgroundViewPositionSingleLine) ) {
            [_bgView setFrame:CGRectMake(0, 1, bounds.size.width, bounds.size.height -2)];
        } else {
            [_bgView setFrame:bounds];
        }
        [_bgView setNeedsDisplay];
    } else if ([self.backgroundView isKindOfClass:[TiSelectedCellBackgroundView class]]) {
        [self.backgroundView setNeedsDisplay];
    }
	[super layoutSubviews];
	if (_templateStyle == TiUIListItemTemplateStyleCustom) {
		// prevent any crashes that could be caused by unsupported layouts
		_proxy.layoutProperties->layoutStyle = TiLayoutRuleAbsolute;
		[_proxy layoutChildren:NO];
	}
}

#pragma mark - Background Support
-(BOOL) selectedOrHighlighted
{
	return [self isSelected] || [self isHighlighted];
}

-(void) updateGradientLayer:(BOOL)useSelected withAnimation:(BOOL)animated
{
	TiGradient * currentGradient = useSelected?selectedBackgroundGradient:backgroundGradient;
    
	if(currentGradient == nil)
	{
		[gradientLayer removeFromSuperlayer];
		//Because there's the chance that the other state still has the gradient, let's keep it around.
		return;
	}
    
	
	if(gradientLayer == nil)
	{
		gradientLayer = [[TiGradientLayer alloc] init];
		[gradientLayer setNeedsDisplayOnBoundsChange:YES];
		[gradientLayer setFrame:[self bounds]];
	}
    
	[gradientLayer setGradient:currentGradient];

	CALayer * ourLayer = [[[self contentView] layer] superlayer];
	
	if([gradientLayer superlayer] != ourLayer)
	{
		CALayer* contentLayer = [[self contentView] layer];
		[ourLayer insertSublayer:gradientLayer below:contentLayer];
    }
    if (animated) {
        CABasicAnimation *flash = [CABasicAnimation animationWithKeyPath:@"opacity"];
        flash.fromValue = [NSNumber numberWithFloat:0.0];
        flash.toValue = [NSNumber numberWithFloat:1.0];
        flash.duration = 1.0;
        [gradientLayer addAnimation:flash forKey:@"flashAnimation"];
    }
	[gradientLayer setNeedsDisplay];
}

-(void) setBackgroundGradient_:(id)value
{
	TiGradient * newGradient = [TiGradient gradientFromObject:value proxy:_proxy];
	if(newGradient == backgroundGradient)
	{
		return;
	}
	[backgroundGradient release];
	backgroundGradient = [newGradient retain];
	
	if(![self selectedOrHighlighted])
	{
		[self updateGradientLayer:NO withAnimation:NO];
	}
}

-(void) setSelectedBackgroundGradient_:(id)value
{
	TiGradient * newGradient = [TiGradient gradientFromObject:value proxy:_proxy];
	if(newGradient == selectedBackgroundGradient)
	{
		return;
	}
	[selectedBackgroundGradient release];
	selectedBackgroundGradient = [newGradient retain];
	
	if([self selectedOrHighlighted])
	{
		[self updateGradientLayer:YES withAnimation:NO];
	}
}

-(void)setPosition:(int)position isGrouped:(BOOL)grouped
{
    _positionMask = position;
    _grouped = grouped;
}

            
-(BOOL)compareDataItemValue:(NSString*)theKey withItem:(NSDictionary *)otherItem
{
    id propertiesValue = [_dataItem objectForKey:@"properties"];
    NSDictionary *properties = ([propertiesValue isKindOfClass:[NSDictionary class]]) ? propertiesValue : nil;
    id curValue = [properties objectForKey:theKey];
    
    propertiesValue = [otherItem objectForKey:@"properties"];
    properties = ([propertiesValue isKindOfClass:[NSDictionary class]]) ? propertiesValue : nil;
    id otherValue = [properties objectForKey:theKey];
    return ( (curValue == otherValue) || [curValue isEqual:otherValue]);

}

- (BOOL)canApplyDataItem:(NSDictionary *)otherItem;
{
    id template = [_dataItem objectForKey:@"template"];
    id otherTemplate = [otherItem objectForKey:@"template"];
    BOOL same = (template == otherTemplate) || [template isEqual:otherTemplate];
    if (same) {
        same = [self compareDataItemValue:@"height" withItem:otherItem];
    }
    //These properties are applied in willDisplayCell. So force reload.
    if (same) {
        same = [self compareDataItemValue:@"backgroundColor" withItem:otherItem];
	}
    if (same) {
        same = [self compareDataItemValue:@"backgroundImage" withItem:otherItem];
	}
    if (same) {
        same = [self compareDataItemValue:@"tintColor" withItem:otherItem];
	}
	return same;
}

- (void)configureCellBackground
{
    //Ensure that we store the default backgroundColor
    if ([_initialValues objectForKey:@"backgroundColor"] == nil) {
        id initialValue = nil;
        if (_templateStyle == TiUIListItemTemplateStyleCustom) {
            initialValue = [[TiUtils colorValue:[_proxy valueForKey:@"backgroundColor"]] color];
        }
        if (IS_NULL_OR_NIL(initialValue)) {
            initialValue = [self backgroundColor];
        }
        [_initialValues setObject:(initialValue != nil ? initialValue : [NSNull null]) forKey:@"backgroundColor"];
    }
    id propertiesValue = [_dataItem objectForKey:@"properties"];
    NSDictionary *properties = ([propertiesValue isKindOfClass:[NSDictionary class]]) ? propertiesValue : nil;
    id colorValue = [properties objectForKey:@"backgroundColor"];
    UIColor *color = colorValue != nil ? [[TiUtils colorValue:colorValue] _color] : nil;
    if (color == nil) {
        id initVal = [_initialValues objectForKey:@"backgroundColor"];
        if ([initVal isKindOfClass:[UIColor class]]) {
            color = initVal;
        } else {
            color = [[TiUtils colorValue:initVal] color];
        }
    }
    self.backgroundColor = color;
    
    //Ensure that we store the backgroundImage
    if ([_initialValues objectForKey:@"backgroundImage"] == nil) {
        id initialValue = nil;
        if (_templateStyle == TiUIListItemTemplateStyleCustom) {
            initialValue = [_proxy valueForKey:@"backgroundImage"];
        }
        [_initialValues setObject:(initialValue != nil ? initialValue : [NSNull null]) forKey:@"backgroundImage"];
    }
    id backgroundImage = [properties objectForKey:@"backgroundImage"];
    if (IS_NULL_OR_NIL(backgroundImage)) {
        backgroundImage = [_initialValues objectForKey:@"backgroundImage"];
    }
    UIImage* bgImage = [[ImageLoader sharedLoader] loadImmediateStretchableImage:[TiUtils toURL:backgroundImage proxy:_proxy] withLeftCap:TiDimensionAuto topCap:TiDimensionAuto];
    if (_grouped && ![TiUtils isIOS7OrGreater]) {
        UIView* superView = [self backgroundView];
        if (bgImage != nil) {
            if (![_bgView isKindOfClass:[UIImageView class]]) {
                [_bgView removeFromSuperview];
                RELEASE_TO_NIL(_bgView);
                _bgView = [[UIImageView alloc] initWithFrame:CGRectZero];
                _bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                [superView addSubview:_bgView];
            }
            [(UIImageView*)_bgView setImage:bgImage];
            [_bgView setBackgroundColor:[UIColor clearColor]];
        } else {
            [_bgView removeFromSuperview];
            RELEASE_TO_NIL(_bgView);
        }
    } else {
        if (bgImage != nil) {
            //Set the backgroundView to ImageView and set its backgroundColor to bgColor
            if ([self.backgroundView isKindOfClass:[UIImageView class]]) {
                [(UIImageView*)self.backgroundView setImage:bgImage];
                [(UIImageView*)self.backgroundView setBackgroundColor:[UIColor clearColor]];
            } else {
                UIImageView *view_ = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
                [view_ setImage:bgImage];
                [view_ setBackgroundColor:[UIColor clearColor]];
                self.backgroundView = view_;
            }
        } else {
            self.backgroundView = nil;
        }
    }
    
}

- (void)setDataItem:(NSDictionary *)dataItem
{
	_dataItem = [dataItem retain];
	[_resetKeys addObjectsFromArray:[_currentValues allKeys]];
	id propertiesValue = [dataItem objectForKey:@"properties"];
	NSDictionary *properties = ([propertiesValue isKindOfClass:[NSDictionary class]]) ? propertiesValue : nil;
	switch (_templateStyle) {
		default:
			[dataItem enumerateKeysAndObjectsUsingBlock:^(NSString *bindId, id dict, BOOL *stop) {
				if (![dict isKindOfClass:[NSDictionary class]] || [bindId isEqualToString:@"properties"]) {
					return;
				}
				id bindObject = [self valueForUndefinedKey:bindId];
				if (bindObject != nil) {
					BOOL reproxying = NO;
					if ([bindObject isKindOfClass:[TiProxy class]]) {
						[bindObject setReproxying:YES];
						reproxying = YES;
					}
					[(NSDictionary *)dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
						NSString *keyPath = [NSString stringWithFormat:@"%@.%@", bindId, key];
						if ([self shouldUpdateValue:value forKeyPath:keyPath]) {
							[self recordChangeValue:value forKeyPath:keyPath withBlock:^{
								[bindObject setValue:value forKey:key];
							}];
						}
					}];
					if (reproxying) {
						[bindObject setReproxying:NO];
					}
				}
			}];
			break;
	}
    
    id backgroundGradientValue = [properties objectForKey:@"backgroundGradient"];
    if (IS_NULL_OR_NIL(backgroundGradientValue)) {
        backgroundGradientValue = [_proxy valueForKey:@"backgroundGradient"];
    }
    [self setBackgroundGradient_:backgroundGradientValue];
	
    
    id selectedBackgroundGradientValue = [properties objectForKey:@"selectedBackgroundGradient"];
    if (IS_NULL_OR_NIL(selectedBackgroundGradientValue)) {
        backgroundGradientValue = [_proxy valueForKey:@"selectedBackgroundGradient"];
    }
    [self setSelectedBackgroundGradient_:selectedBackgroundGradientValue];
	
    id selectedbackgroundColorValue = [properties objectForKey:@"selectedBackgroundColor"];
    if (IS_NULL_OR_NIL(selectedbackgroundColorValue)) {
        selectedbackgroundColorValue = [_proxy valueForKey:@"selectedBackgroundColor"];
    }

    id selectedBackgroundImageValue = [properties objectForKey:@"selectedBackgroundImage"];
    if (IS_NULL_OR_NIL(selectedBackgroundImageValue)) {
        selectedBackgroundImageValue = [_proxy valueForKey:@"selectedBackgroundImage"];
    }

	[_resetKeys enumerateObjectsUsingBlock:^(NSString *keyPath, BOOL *stop) {
		id value = [_initialValues objectForKey:keyPath];
		[self setValue:(value != [NSNull null] ? value : nil) forKeyPath:keyPath];
		[_currentValues removeObjectForKey:keyPath];
	}];
	[_resetKeys removeAllObjects];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return [self.bindings objectForKey:key];
}

- (void)recordChangeValue:(id)value forKeyPath:(NSString *)keyPath withBlock:(void(^)(void))block
{
	if ([_initialValues objectForKey:keyPath] == nil) {
		id initialValue = [self valueForKeyPath:keyPath];
		[_initialValues setObject:(initialValue != nil ? initialValue : [NSNull null]) forKey:keyPath];
	}
	block();
	if (value != nil) {
		[_currentValues setObject:value forKey:keyPath];
	} else {
		[_currentValues removeObjectForKey:keyPath];
	}
	[_resetKeys removeObject:keyPath];
}

- (BOOL)shouldUpdateValue:(id)value forKeyPath:(NSString *)keyPath
{
	id current = [_currentValues objectForKey:keyPath];
	BOOL sameValue = ((current == value) || [current isEqual:value]);
	if (sameValue) {
		[_resetKeys removeObject:keyPath];
	}
	return !sameValue;
}

#pragma mark - Static 

+ (void)buildBindingsForViewProxy:(TiViewProxy *)viewProxy intoDictionary:(NSMutableDictionary *)dict
{
	[viewProxy.children enumerateObjectsUsingBlock:^(TiViewProxy *childViewProxy, NSUInteger idx, BOOL *stop) {
		[[self class] buildBindingsForViewProxy:childViewProxy intoDictionary:dict];
	}];
	id bindId = [viewProxy valueForKey:@"bindId"];
	if (bindId != nil) {
		[dict setObject:viewProxy forKey:bindId];
	}
}

@end