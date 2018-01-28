//
//  TiSearchDisplayController.h
//  TiCollectionView
//
//  Created by Ayorinde Adesugba on 1/29/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol TiSearchDisplayDelegate;

@interface TiSearchDisplayController : NSObject<UISearchBarDelegate>

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController;
- (void)setActive:(BOOL)visible animated:(BOOL)animated;

@property(nonatomic,assign) id<TiSearchDisplayDelegate> delegate;
@property(nonatomic, getter = isActive) BOOL active;
@property(nonatomic, readonly) UISearchBar *searchBar;
@property(nonatomic, readonly) UIViewController *searchContentsController;
@property(nonatomic, readonly) UICollectionView *searchResultsCollectionView;
@property(nonatomic, assign) id<UICollectionViewDataSource> searchResultsDataSource;
@property(nonatomic, assign) id<UICollectionViewDelegate> searchResultsDelegate;

@end



@protocol TiSearchDisplayDelegate <NSObject>

@optional

- (void)searchDisplayControllerWillBeginSearch:(TiSearchDisplayController *)controller;
- (void)searchDisplayControllerDidBeginSearch:(TiSearchDisplayController *)controller;
- (void)searchDisplayControllerWillEndSearch:(TiSearchDisplayController *)controller;
- (void)searchDisplayControllerDidEndSearch:(TiSearchDisplayController *)controller;
- (void)textDidChange:(NSString *)searchText;
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope;

@end
