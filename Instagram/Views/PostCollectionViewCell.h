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

//methods
- (void)setCellWithPost:(Post *)post;

@end

NS_ASSUME_NONNULL_END
