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
#import "CollectionReusableView.h"

#define COLLECTION_VIEW_PADDING 60
@interface ViewController () <UICollectionViewDelegateFlowLayout>

{
    IBOutlet UICollectionView *_collectionview;
}
@property (assign, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, retain) VKPlayerControllerTV *player;
@property (strong, nonatomic) NSMutableArray *movies;

@end

@implementation ViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.movies = [NSMutableArray new];
    self.navigationController.navigationBar.hidden = YES;
    [self fetchMovies];
   // UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
   // collectionViewLayout.sectionInset = UIEdgeInsetsMake(20, 0, 20, 0);
    
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
    
    return CGSizeMake(height * (9.0/08.0), height);
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
    
    return cell;
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        CollectionReusableView *headerViews = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        NSString *title = [[NSString alloc]initWithFormat:@"RAILSCAST VIDEO ON APPLE TV ", indexPath.section + 1];
        headerViews.headerView.text = title;
        reusableview = headerViews;
        
    }
       return reusableview;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    Movie *movie = [self.movies objectAtIndex:indexPath.row];
    NSLog(@"uurllllllll...........>%@",movie.videoURL);
    
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





@end
