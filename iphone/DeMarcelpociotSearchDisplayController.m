//
//  DeMarcelpociotSearchDisplayController.m
//  TiCollectionView
//
//  Created by Ayorinde Adesugba on 1/29/15.
//
//

#import "DeMarcelpociotSearchDisplayController.h"

@implementation DeMarcelpociotSearchDisplayController

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController {
    self = [super init];
    
    if (self) {
        _searchBar = searchBar;
        _searchBar.delegate = self;
        _searchContentsController = viewController;
        
        CGFloat y = 64.0f;
        CGFloat height = _searchContentsController.view.frame.size.height - y;
        
        UICollectionViewFlowLayout* layout = [[UICollectionViewFlowLayout alloc] init];
        _searchResultsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0f, y, _searchContentsController.view.frame.size.width, height) collectionViewLayout:layout];
        _searchResultsCollectionView.scrollsToTop = NO;
    }
    
    return self;
}

- (void)setSearchResultsDataSource:(id<UICollectionViewDataSource>)searchResultsDataSource {
    _searchResultsCollectionView.dataSource = searchResultsDataSource;
}

- (void)setSearchResultsDelegate:(id<UICollectionViewDelegate>)searchResultsDelegate {
    _searchResultsCollectionView.delegate = searchResultsDelegate;
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated {
    NSLog(@"[INFO] setActive called");
    if (!visible) {
        [_searchBar resignFirstResponder];
        _searchBar.text = nil;
        _searchBar.showsCancelButton = NO;
    }
    
    if (visible && [self.delegate respondsToSelector:@selector(searchDisplayControllerWillBeginSearch:)]) {
        [self.delegate searchDisplayControllerWillBeginSearch:self];
    } else if (!visible && [self.delegate respondsToSelector:@selector(searchDisplayControllerWillEndSearch:)]) {
        [self.delegate searchDisplayControllerWillEndSearch:self];
    }
    
    [_searchContentsController.navigationController setNavigationBarHidden:visible animated:YES];
    
    float alpha = 0;
    
    if (visible) {
        [_searchContentsController.view addSubview:_searchResultsCollectionView];
        alpha = 0.2;
    }
    
    if ([_searchContentsController.view respondsToSelector:@selector(scrollEnabled)]) {
        ((UIScrollView *)_searchContentsController.view).scrollEnabled = !visible;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            _searchResultsCollectionView.alpha = alpha;
        } completion:^(BOOL finished) {
            self.active = visible;
        }];
    } else {
        _searchResultsCollectionView.alpha = alpha;
    }
}



#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if ([self.delegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)]) {
        [self.delegate searchBar:searchBar selectedScopeButtonIndexDidChange:selectedScope];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([self.delegate respondsToSelector:@selector(textDidChange:)]) {
        [self.delegate textDidChange:searchText];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    [self setActive:YES animated:YES];
    [_searchResultsCollectionView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_searchResultsCollectionView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self setActive:NO animated:YES];
    [self.searchResultsCollectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}


@end
