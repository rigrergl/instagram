//
//  FeedViewController.m
//  Instagram
//
//  Created by Rigre Reinier Garciandia Larquin on 7/4/21.
//

#import "FeedViewController.h"
#import "Utility.h"
#import "AppDelegate.h"
#import "SceneDelegate.h"
#import "UserAuthenticationViewController.h"
#import  "PostCollectionViewCell.h"
#import  "ComposeCommentViewController.h"
#import "PostDetailsViewController.h"
#import "ProfileViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface FeedViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate>

@property (strong, nonatomic) NSMutableArray *_Nullable posts;
@property (strong, nonatomic) IBOutlet UICollectionView *_Nonnull collectionView;
@property (nonatomic, strong) UIRefreshControl *_Nonnull refreshControl;
@property (assign, nonatomic) BOOL isMoreDataLoading;
@property (assign, nonatomic) BOOL isDragging;
@property (strong, nonatomic) NSDate *_Nullable dateOfLastLoadedPost;

@end

@implementation FeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isDragging = false;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchData) forControlEvents:UIControlEventValueChanged];
    [self.collectionView insertSubview:self.refreshControl atIndex:0];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"PostCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PostCollectionViewCell"];
    
    UICollectionViewFlowLayout *layout = self.collectionView.collectionViewLayout;
    layout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize;
    
    //setting navbar image
    UIImage *instagramLetterLogo = [Utility resizeImage:[UIImage imageNamed:@"1200px-instagram_logo.svg"] withSize:CGSizeMake(150, 50)];
    UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:instagramLetterLogo]];
    self.navigationItem.leftBarButtonItem = item;
    
    [self fetchData];
}

- (void)fetchData {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.collectionView.alpha = 0;
    
    // construct query
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query includeKey:@"author"];
    [query orderByDescending:@"createdAt"];
    query.limit = 20;

    
    // fetch data asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            self.posts = posts;
            
            if (self.posts.count > 0) {
                self.dateOfLastLoadedPost = ((Post*) posts[posts.count - 1]).createdAt;
            }
            
            //resetting isLikedByCurrentUser
            for (Post *post in posts) {
                post.isLikedByCurrentUser = NO;
            }
            
            //set isLikedByCurrentUser for each post received
            PFQuery *likesQuery = [PFQuery queryWithClassName:@"Like"];
            [likesQuery whereKey:@"userId" equalTo:[PFUser currentUser]];

            [likesQuery findObjectsInBackgroundWithBlock:^(NSArray *likes, NSError *error){
                if (error) {
                    NSLog(@"Error fetching likes");
                } else {
                    for (Post *post in self.posts) {
                        for(PFObject *like in likes) {
                            if([post.objectId isEqualToString: like[@"postId"]]){
                                post.isLikedByCurrentUser = YES;
                            }
                        }
                    }
                }
                [self.refreshControl endRefreshing];
                [self.collectionView reloadData];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [UIView animateWithDuration:.5 animations:^{
                    self.collectionView.alpha = 1;
                }];
            }];
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (IBAction)didTapCompose:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"feedToCompose" sender:self];
}

#pragma mark - CollectionView methods

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.posts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PostCollectionViewCell" forIndexPath:indexPath];
    
    CGFloat safeAreaWidth = self.view.safeAreaLayoutGuide.layoutFrame.size.width;
    [cell setCellWithPost:self.posts[indexPath.item] screenWidth:safeAreaWidth commentCode:^(PostCollectionViewCell *postCell){
        [self performSegueWithIdentifier:@"feedToComment" sender:postCell];
    } didTapPostImage:^(PostCollectionViewCell *postCell){
        [self performSegueWithIdentifier:@"feedToPostDetails" sender:postCell.post];
    } didTapProfileImage:^(PostCollectionViewCell *postCell){
        [self performSegueWithIdentifier:@"feedToUserProfile" sender:postCell.post.author];
    }];
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(!self.isMoreDataLoading){
         // Calculate the position of one screen length before the bottom of the results
         int scrollViewContentHeight = self.collectionView.contentSize.height;
         int scrollOffsetThreshold = scrollViewContentHeight * 0.9;
         
         // When the user has scrolled past the threshold, start requesting
         if(scrollView.contentOffset.y > scrollOffsetThreshold && self.collectionView.isDragging && !self.isDragging) {
             self.isMoreDataLoading = true;
             
             // ... Code to load more results ...
             [self loadMoreData];
         }
     }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.isDragging = false;
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isDragging = true;
}

- (void)loadMoreData {
    NSLog(@"Load more data");
    
    
    // construct query
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query includeKey:@"author"];
    
    NSDate *now = [NSDate now];
    
    if (self.dateOfLastLoadedPost != nil) {
        [query whereKey:@"createdAt" greaterThan:self.dateOfLastLoadedPost];
    }
    [query orderByDescending:@"createdAt"];
    query.limit = 20;

    // fetch data asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            
            self.collectionView.alpha = 0;
            [UIView animateWithDuration:.5 animations:^{
                [self.posts addObjectsFromArray:posts];
                self.collectionView.alpha = 1;
            }];
            
            //resetting isLikedByCurrentUser
            for (Post *post in posts) {
                post.isLikedByCurrentUser = NO;
            }
            
            //set isLikedByCurrentUser for each post received
            PFQuery *likesQuery = [PFQuery queryWithClassName:@"Like"];
            [likesQuery whereKey:@"userId" equalTo:[PFUser currentUser]];

            [likesQuery findObjectsInBackgroundWithBlock:^(NSArray *likes, NSError *error){
                if (error) {
                    NSLog(@"Error fetching likes");
                } else {
                    for (Post *post in self.posts) {
                        for(PFObject *like in likes) {
                            if([post.objectId isEqualToString: like[@"postId"]]){
                                post.isLikedByCurrentUser = YES;
                            }
                        }
                    }
                }
                self.isMoreDataLoading = false;
                [self.collectionView reloadData];
            }];
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"feedToComment"]) {
        
        PostCollectionViewCell *postCell = (PostCollectionViewCell *) sender;
        ComposeCommentViewController *destinationController = [segue destinationViewController];
        destinationController.postCell = postCell;
        
    } else if ([segue.identifier isEqualToString:@"feedToPostDetails"]){
        
        Post *post = (Post *) sender;
        PostDetailsViewController *postDetailsViewController = [segue destinationViewController];
        postDetailsViewController.post = post;
        
    } else if ([segue.identifier isEqualToString:@"feedToUserProfile"]) {
        //TODO: prepare segue
        PFUser *targetUser = (PFUser *) sender;
        ProfileViewController *profileViewController = [segue destinationViewController];
        profileViewController.targetUser = targetUser;
    }
}


@end
