//
//  DeMarcelpociotCollectionviewHeaderFooterReusableView.m
//  TiCollectionView
//
//  Created by Ayorinde Adesugba on 1/28/15.
//
//

#import "DeMarcelpociotCollectionviewHeaderFooterReusableView.h"

@implementation DeMarcelpociotCollectionviewHeaderFooterReusableView

- (id)initWithFrame:(CGRect)frame
{
    NSLog(@"[INFO] initWithFrame");
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //[self setBounds:CGRectMake(0, 0, 320.f, 50.f)];
        //[self setBackgroundColor:[UIColor yellowColor]];

    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSLog(@"[INFO] initWithCoder");
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code

    }
    return self;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    
}

@end
