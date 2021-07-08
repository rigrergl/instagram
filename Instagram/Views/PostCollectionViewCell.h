//
//  PostCollectionViewCell.h
//  Instagram
//
//  Created by Rigre Reinier Garciandia Larquin on 7/5/21.
//

#import <UIKit/UIKit.h>
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@interface PostCollectionViewCell : UICollectionViewCell

//properties
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *postImage;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) Post *post;
@property (nonatomic, copy) void (^commentMethod)(PostCollectionViewCell *postCell);
@property (nonatomic, copy) void (^didTapPostImage)(PostCollectionViewCell *postCell);
@property (nonatomic, copy) void (^didTapProfileImage)(PostCollectionViewCell *postCell);

//methods
- (void)setCellWithPost:(Post *)post screenWidth:(CGFloat)screenWidth commentCode:(void(^)(PostCollectionViewCell *post))commentCode didTapPostImage:(void(^)(PostCollectionViewCell *postCell))didTapPostImage didTapProfileImage:(void(^)(PostCollectionViewCell *postCell))didTapProfileImage;
- (void)refreshUI;

@end

NS_ASSUME_NONNULL_END
