//
//  ViewController.m
//  TVOSExample
//
//  Created by Christian Lysne on 13/09/15.
//  Copyright © 2015 Christian Lysne. All rights reserved.
//

#import "ViewController.h"
#import "MovieCollectionViewCell.h"
#import "Movie.h"
#import "RestHandler.h"
#import "MovieViewController.h"
#import "VKPlayerControllerTV.h"


#define COLLECTION_VIEW_PADDING 60

@interface ViewController () <UICollectionViewDelegateFlowLayout>
{
IBOutlet UICollectionView *_collectionview;
}

@property (assign, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *movies;
@property (nonatomic, retain) VKPlayerControllerTV *player;

@end

@implementation ViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.movies = [NSMutableArray new];
    
    [self fetchMovies];
}

#pragma mark - Data
- (void)fetchMovies {
    [[RestHandler sharedInstance] fetchMovies:^(NSArray *movies) {
       
        self.movies = [NSMutableArray arrayWithArray:movies];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.collectionView reloadData];
            
        });
        
    } failure:^(NSError *error) {
        
    }];
}

#pragma mark - UICollectionView
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = (CGRectGetHeight(self.view.frame)-(2*COLLECTION_VIEW_PADDING))/2;
    
    return CGSizeMake(height * (9.0/16.0), height);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.movies.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MovieCollectionViewCell* cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"movieCell"
                                                                           forIndexPath:indexPath];
    cell.indexPath = indexPath;
    
    Movie *movie = [self.movies objectAtIndex:indexPath.row];
    
    [cell updateCellForMovie:movie];
    
//    if (cell.gestureRecognizers.count == 0) {
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectItemAtIndexPath:)];
//        tap.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
//        [cell addGestureRecognizer:tap];
//    }
    
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    
     Movie *movie = [self.movies objectAtIndex:indexPath.row];
    
    NSLog(@"uurllllllll...........>%@",movie.videoURL);
//    
    VKPlayerViewController *playerVc = [[[VKPlayerViewController alloc] initWithURLString:movie.videoURL
    decoderOptions:nil] autorelease];
    playerVc.statusBarHidden = YES;
    playerVc.delegate = self;
    
     [self.navigationController presentViewController:playerVc animated:YES completion:NULL];
     [movie.videoURL release];
}
- (void)onPlayerViewControllerStateChanged:(VKDecoderState)state errorCode:(VKError)errCode {
    if (state == kVKDecoderStateConnecting) {
    } else if (state == kVKDecoderStateConnected) {
    } else if (state == kVKDecoderStateInitialLoading) {
    } else if (state == kVKDecoderStateReadyToPlay) {
    } else if (state == kVKDecoderStateBuffering) {
    } else if (state == kVKDecoderStatePlaying) {
    } else if (state == kVKDecoderStatePaused) {
    } else if (state == kVKDecoderStateStoppedByUser) {
    } else if (state == kVKDecoderStateConnectionFailed) {
    } else if (state == kVKDecoderStateStoppedWithError) {
        if (errCode == kVKErrorStreamReadError) {
        }
    }
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_collectionView release];
    [super dealloc];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - GestureRecognizer
//- (void)tappedMovie:(UITapGestureRecognizer *)gesture {
//    
//    if (gesture.view != nil) {
//        
//        
//        MovieCollectionViewCell* cell = (MovieCollectionViewCell *)gesture.view;
//        Movie *movie = [self.movies objectAtIndex:cell.indexPath.row];
//        
//        MovieViewController *movieVC = (id)[self.storyboard instantiateViewControllerWithIdentifier:@"Movie"];
//        movieVC.movie = movie;
//        [self presentViewController:movieVC animated:YES completion: nil];
//    }
//    
//}

#pragma mark - Focus
//- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
//    
//    if (context.previouslyFocusedView != nil) {
//        
//        MovieCollectionViewCell *cell = (MovieCollectionViewCell *)context.previouslyFocusedView;
//        cell.titleLabel.font = [UIFont systemFontOfSize:20];
//    }
//    
//    if (context.nextFocusedView != nil) {
//        
//        MovieCollectionViewCell *cell = (MovieCollectionViewCell *)context.nextFocusedView;
//        cell.titleLabel.font = [UIFont boldSystemFontOfSize:20];
//    }
//}

@end
